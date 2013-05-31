class MainController < Controller

  def index
    return unless login_required

    external_ip_fallback = '<span class="none">none</span>'
    @external_ip = (APP_CONFIG['info']['external_ip'] || external_ip_fallback) rescue external_ip_fallback
  end

end
