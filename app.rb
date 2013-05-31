# This file contains your application, it requires dependencies and necessary
# parts of the application.
require 'rubygems'
require 'yaml'
require 'ramaze'

# Load app configuration
config_path = __DIR__('app.yml')
config_path = OPTIONS[:config] if defined?(OPTIONS)
APP_CONFIG = {
    'auth' => {
      'username' => 'admin',
      'password' => '-'
    }
  }.merge(YAML.load_file(config_path))

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

require __DIR__('lib/ts-admin/traffic_server')
require __DIR__('controller/init')
