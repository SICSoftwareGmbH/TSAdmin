require 'digest/sha1'
require 'uri'

module TSAdmin
  class TrafficServer
    MARKER_TEXT = "CONFIGURATION FROM TSADMIN"

    class RemapError < StandardError; end

    class ValidatingArray < Array
      class InvalidObject < StandardError; end
      def add(o)
        raise InvalidObject unless o.respond_to?(:valid?) && o.valid?
        super
      end
      def method_missing(m, *args, &block)
        if m.to_s =~ /^get_(\w+)$/ && args.count == 1
          select{|i| i.respond_to?($1) && i.send($1) == args[0]}
        else
          super
        end
      end
    end

    class RemapEntry
      attr_accessor :type, :id, :from, :to

      def initialize(ts, type, from, to)
        @ts = ts
        @type = type.to_sym
        @from = from.downcase
        @to = to.downcase
        @id = Digest::SHA1.hexdigest(@from)
      end

      def valid?
        errors.count == 0
      end

      def errors
        e = []
        e << :type_invalid unless [:map, :redirect].include?(@type)
        e << :from_invalid unless valid_url?(@from)
        e << :to_invalid unless valid_url?(@to)
        e << :duplicate_entry unless @ts.remap_entries.get_from(@from).select{|e| e != self}.count == 0
        e.compact.uniq
      end

      private

      def valid_url?(url)
        !!(url =~ URI::regexp) rescue false
      end
    end

    def initialize(options={})
      @options = {
          'config_path' => '/etc/trafficserver',
          'restart_cmd' => '/etc/init.d/trafficserver restart'
        }.merge(options)
      @config_path = @options['config_path']
    end

    def remap_entries
      load unless defined?(@remap_entries)
      @remap_entries
    end

    def new_remap_entry(type, from, to)
      RemapEntry.new(self, type, from, to)
    end

    def save
      own_config = ''
      own_config << "#{self.class.marker_begin}\n"
      remap_entries.each do |remap_entry|
        own_config << "#{remap_entry.type.to_s} #{remap_entry.from} #{remap_entry.to}\n"
      end
      own_config << "#{self.class.marker_end}\n"

      file_content = ''
      in_config_block = false
      own_config_written = false
      File.read(remap_path).each_line do |line|
        if line.strip == self.class.marker_begin
          in_config_block = true
          next
        elsif line.strip == self.class.marker_end
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

    def remap_path
      File.join(@config_path, 'remap.config')
    end

    def load
      @remap_entries = ValidatingArray.new

      in_config_block = false
      File.read(remap_path).each_line do |line|
        if line.strip == self.class.marker_begin
          in_config_block = true
          next
        elsif line.strip == self.class.marker_end
          in_config_block = false
          next
        end

        next unless in_config_block

        type, from, to, *options = line.split(/\s+/)
        @remap_entries << RemapEntry.new(self, type, from, to)
        @remap_entries.delete_if{|e| !e.valid?}
      end
    end

    def self.marker_begin
      "# BEGIN #{MARKER_TEXT}"
    end

    def self.marker_end
      "# END #{MARKER_TEXT}"
    end
  end
end
