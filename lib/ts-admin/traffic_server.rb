require 'digest/sha1'
require 'uri'

module TSAdmin
  class TrafficServer
    MARKER_TEXT = "CONFIGURATION FROM TSADMIN"

    def initialize(options={})
      @options = {
          'config_path' => '/etc/trafficserver',
          'restart_cmd' => '/etc/init.d/trafficserver restart'
        }.merge(options)
      @config_path = @options['config_path']
    end

    def redirects
      load unless defined?(@redirects)
      @redirects.dup.freeze
    end

    def maps
      load unless defined?(@maps)
      @maps.dup.freeze
    end

    def find_remap_by_id(id)
      (maps + redirects).select{|m| m[:id] == id}.first
    end

    def add_remap(type, from, to, options={})
      load

      return unless list = case type.to_sym
        when :map
          @maps
        when :redirect
          @redirects
        else
          nil
        end

      id = Digest::SHA1.hexdigest("#{from}_#{to}")

      return false if find_remap_by_id(id)
      return false unless validate_url(from) && validate_url(to)

      list << {:id => id, :type => type.to_sym, :from => from, :to => to, :options => options}

      true
    end

    def edit_remap(id, from, to, options=nil)
      return false unless validate_url(from) && validate_url(to)
      return false unless entry = find_remap_by_id(id)
      entry[:from] = from
      entry[:to] = to
      entry[:options] = options unless options.nil?
      entry[:id] = Digest::SHA1.hexdigest("#{from}_#{to}")
    end

    def delete_remap(id)
      load

      @maps.delete_if{|m| m[:id] == id}
      @redirects.delete_if{|m| m[:id] == id}

      true
    end

    def save
      own_config = ''
      own_config << "#{marker_begin}\n"
      redirects.each do |redirect|
        own_config << "redirect #{redirect[:from]} #{redirect[:to]} #{redirect[:options] if redirect[:options]}\n"
      end
      maps.each do |map|
        own_config << "map #{map[:from]} #{map[:to]} #{map[:options] if map[:options]}\n"
      end
      own_config << "#{marker_end}\n"

      file_content = ''
      in_config_block = false
      own_config_written = false
      File.read(remap_path).each_line do |line|
        if line.strip == marker_begin
          in_config_block = true
          next
        elsif line.strip == marker_end
          in_config_block = false
          next
        end

        if in_config_block
          file_content << own_config unless own_config_written
          own_config_written = true
        else
          file_content << line
        end
      end
      file_content << own_config unless own_config_written

      remap_file = File.new(remap_path, 'w')
      remap_file.write(file_content)
      remap_file.close
    end

    def restart
      `#{@options['restart_cmd']}`
    end

    private

    def marker_begin
      "# BEGIN #{MARKER_TEXT}"
    end

    def marker_end
      "# END #{MARKER_TEXT}"
    end

    def remap_path
      File.join(@config_path, 'remap.config')
    end

    def load
      @redirects = []
      @maps = []

      in_config_block = false
      File.read(remap_path).each_line do |line|
        if line.strip == marker_begin
          in_config_block = true
          next
        elsif line.strip == marker_end
          in_config_block = false
          next
        end

        next unless in_config_block

        type, from, to, *options = line.split(/\s+/)
        id = Digest::SHA1.hexdigest("#{from}_#{to}")
        case type.to_sym
        when :redirect
          @redirects << {:id => id, :type => type.to_sym, :from => from, :to => to, :options => {}}
        when :map
          @maps << {:id => id, :type => type.to_sym, :from => from, :to => to, :options => {}}
        end
      end
    end

    def validate_url(url)
      !!(url =~ URI::regexp) rescue false
    end

  end
end
