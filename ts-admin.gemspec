# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ts-admin/version'

Gem::Specification.new do |spec|
  spec.name          = "ts-admin"
  spec.version       = TSAdmin::VERSION
  spec.authors       = ["Florian Schwab"]
  spec.email         = ["florian.schwab@sic-software.com"]
  spec.description   = %q{Frontend for managing ATS remap configuration}
  spec.summary       = %q{Frontend for managing ATS remap configuration}
  spec.homepage      = "http://www.sic-software.com/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "ramaze", ">= 2.0.0"
end
