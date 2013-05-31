# Apache Traffic Server Frontend

This is a simple web frontend for the remap.config configuration file for the Apache Traffic Server.
It is used to manage reverse proxy mappings and 301 redirects. Please refer to [this blog post](http://blog.sic-software.com/2012/03/02/eine-administrationsoberflache-fur-den-apache-traffic-server/) for more information.

## Installation

    $ gem install ts-admin

## Usage

Create a configuration file:

```yaml
port: 7000

auth:
  username: admin
  password: d033e22ae348aeb5660fc2140aec35850c4da997 # SHA1 hash

traffic_server:
  config_path: /etc/trafficserver
  restart_cmd: /etc/init.d/trafficserver restart

info:
  external_ip: 192.168.0.1
```

Start the server:

    $ ts-admin --config /path/to/your/config.yml

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
