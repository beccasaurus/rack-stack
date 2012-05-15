# -*- encoding: utf-8 -*-
require File.expand_path("../lib/rack_apps/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "rack_apps"
  gem.author      = "remi"
  gem.email       = "remi@remitaylor.com"
  gem.homepage    = "http://github.com/remi/rack_apps"
  gem.summary     = "Simple, flexible Rack router."

  gem.description = <<-desc.gsub(/^\s+/, '')
    RackApps is a simple and flexible little Rack router. 

    Rack applications are registered along with request conditions 
    that, when met, route the request to the associated application.

    RackApps can be used as a Rack middleware or application.
  desc

  files = `git ls-files`.split("\n")
  gem.files         = files
  gem.executables   = files.grep(%r{^bin/.*}).map {|f| File.basename(f) }
  gem.test_files    = files.grep(%r{^spec/.*})
  gem.require_paths = ["lib"]
  gem.version       = RackApps::VERSION

  gem.add_dependency "rack"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
end
