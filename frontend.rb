#!/usr/bin/env ruby

require "rubygems"
require "ramaze"

CONFIG_BASEPATH = "/etc/trafficserver"
PASSWORD = "averysecurepassword"
MAP_FILE = File.join(CONFIG_BASEPATH, "remap.config")
MARKER = "# AUTOMATIC CONFIGURATION FROM FRONTEND"

class ConfigurationController < Ramaze::Controller
  include Ramaze::Traited
  helper :auth

  layout "default"
  map "/"

  def auth_login(user, pass)
    session[:logged_in] = true if pass == PASSWORD
  end

  def index
    login_required
    @ts = TSBackend.new
  end

  def add
    login_required
    @ts = TSBackend.new

    # Check if a rule with the same "from" exists
    rule = {:from => request.params["from"], :to => request.params["to"]}
    from_list = (@ts.maps + @ts.redirects).map do |r| r[:from] end
    if from_list.include?(rule[:from])
      flash[:error] = "This rule already exists."
    else
      @ts.maps << rule if request.params["type"] == "map"
      @ts.redirects << rule if request.params["type"] == "redirect"
      @ts.save
    end

    redirect "/"
  end

  def delete
    login_required
    id =  request.params["id"].to_i
    @ts = TSBackend.new
    @ts.maps.delete_at(id) if request.params["type"] == "map"
    @ts.redirects.delete_at(id) if request.params["type"] == "redirect"
    @ts.save
    redirect "/"
  end
end

class TSBackend
  attr_accessor :redirects, :maps
  def initialize
    @redirects = []
    @maps = []

    start_here = false
    File.read(MAP_FILE).each_line do |line|
      unless start_here
        start_here = !!(line =~ /^#{MARKER}$/)
        next
      end

      type, from, to, *rest = line.split(" ")
      case type
      when "redirect"
        @redirects << {:from => from, :to => to}
      when "map"
        @maps << {:from => from, :to => to}
      end
    end
  end

  def save
    file_content = ""
    File.read(MAP_FILE).each_line do |line|
      file_content << line
      break if line =~ /^#{MARKER}$/
    end

    @redirects.each do |redirect|
      file_content << "redirect #{redirect[:from]} #{redirect[:to]}\n"
    end
    file_content << "\n"
    @maps.each do |map|
      file_content << "map #{map[:from]} #{map[:to]}\n"
    end
    f = File.new(MAP_FILE, "w")
    f.write(file_content)
    f.close

    restart
  end

  def restart
    `/etc/init.d/trafficserver restart`
  end
end

# Daemonize
fork {
  Process.setsid
  Ramaze.start
}

