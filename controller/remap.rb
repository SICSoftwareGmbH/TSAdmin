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
      if traffic_server.add_remap(@type, @from, @to)
        traffic_server.save
        restart_traffic_server
        flash[:info] = "Remap entry added"
        call(r('/'))
      else
        flash[:error] = "Invalid Remap entry"
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
      if traffic_server.edit_remap(@id, @from, @to)
        traffic_server.save
        restart_traffic_server
        flash[:info] = "Remap entry updated"
        call(r('/'))
      else
        flash[:error] = "Invalid Remap entry"
        render_view :form
      end
    else
      @entry = traffic_server.find_remap_by_id(@id)
      @from = @entry[:from]
      @to = @entry[:to]
      @type = @entry[:type]
      render_view :form
    end
  end

  def delete
    return unless login_required
    set_env

    traffic_server.delete_remap(request[:id])
    traffic_server.save
    restart_traffic_server

    flash[:info] = "Remap entry removed"

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

end
