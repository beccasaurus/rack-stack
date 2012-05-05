# -*- encoding: utf-8 -*-
require File.expand_path("../lib/rack-conditional-builder/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "rack-conditional-builder"
  gem.author      = "remi"
  gem.email       = "remi@remitaylor.com"
  gem.homepage    = "http://github.com/remi/rack-conditional-builder"
  gem.summary     = "A simple, yet powerful Rack stack/router (inspired by Rack::Builder)"

  gem.description = <<-desc.gsub(/^\s+/, '')
    Rack::ConditionalBuilder is a re-implementation of Rack::Builder 
    with an added feature: each directive (use/run/map) is paired with 
    conditional logic.  This gives you the power of a dynamic Rack stack. 
    Each middleware, for example, can easily be conditionally toggled on 
    or off based on the subdomain of the incoming request.
  desc

  files = `git ls-files`.split("\n")
  gem.files         = files
  gem.executables   = files.grep(%r{^bin/.*}).map {|f| File.basename(f) }
  gem.test_files    = files.grep(%r{^spec/.*})
  gem.require_paths = ["lib"]
  gem.version       = Rack::ConditionalBuilder::VERSION

  gem.add_dependency "rack"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
end
