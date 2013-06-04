class RemapController < Controller

  def index
    return unless login_required
    set_env

    @traffic_server = traffic_server
  end

  def new
    return unless login_required
    set_env

    if request.post?
      @from = request[:from]
      @to = request[:to]
      if (entry = traffic_server.new_remap_entry(@type, @from, @to)).valid?
        traffic_server.remap_entries << entry
        traffic_server.save
        restart_traffic_server
        flash[:info] = "#{entry.type.to_s.capitalize} definition added"
        call(r('/'))
      else
        set_errors(entry)
        render_view :form
      end
    else
      render_view :form
    end
  end

  def edit
    return unless login_required
    set_env

    @id = request[:id]

    if request.post?
      @from = request[:from]
      @to = request[:to]
      if entry = traffic_server.remap_entries.get_id(@id).first
        entry.from = @from
        entry.to = @to
        if entry.valid?
          traffic_server.save
          restart_traffic_server
          flash[:info] = "#{entry.type.to_s.capitalize} definition updated"
          call(r('/'))
        else
          set_errors(entry)
          render_view :form
        end
      else
        flash[:error] = "Remap definition not found"
        render_view :form
      end
    else
      if @entry = traffic_server.remap_entries.get_id(@id).first
        @type = @entry.type
        @from = @entry.from
        @to = @entry.to
        render_view :form
      else
        call(r('/'))
      end
    end
  end

  def delete
    return unless login_required
    set_env

    @id = request[:id]

    if entry = traffic_server.remap_entries.get_id(@id).first
      traffic_server.remap_entries.delete(entry)
      traffic_server.save
      restart_traffic_server
      flash[:info] = "#{entry.type.to_s.capitalize} definition removed"
    end

    call(r('/'))
  end

  private

  def remap_url_highlight_scheme(url)
    scheme, hostpath = url.downcase.split(/:\/\//, 2)
    <<-LINK.strip!
      <span class="#{scheme}">#{scheme}</span>://#{hostpath}
    LINK
  end

  def set_env
    @title = 'Remap'
    @nav = :remap
    @type = request[:type]
  end

  def set_errors(entry)
    case entry.errors.first
    when :type_invalid
      flash[:error] = "Invalid remap type: #{entry.type.to_s}"
    when :from_invalid
      flash[:error] = "Invalid from: #{entry.from.to_s}"
    when :to_invalid
      flash[:error] = "Invalid to: #{entry.to.to_s}"
    when :duplicate_entry
      flash[:error] = "Duplicate remap definition"
    end
  end

end
