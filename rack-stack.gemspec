# -*- encoding: utf-8 -*-
require File.expand_path("../lib/rack-stack/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "rack-stack"
  gem.author      = "remi"
  gem.email       = "remi@remitaylor.com"
  gem.homepage    = "http://github.com/remi/rack-stack"
  gem.summary     = "Managed stack of Rack apps/middleware"

  gem.description = <<-desc.gsub(/^\s+/, '')
    Managed stack of Rack apps/middleware
  desc

  files = `git ls-files`.split("\n")
  gem.files         = files
  gem.executables   = files.grep(%r{^bin/.*}).map {|f| File.basename(f) }
  gem.test_files    = files.grep(%r{^spec/.*})
  gem.require_paths = ["lib"]
  gem.version       = RackStack::VERSION

  gem.add_dependency "rack"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
end

__END__

First Verion of Copy:

    A simple, yet powerful Rack stack/router (inspired by Rack::Builder)

    Rack::ConditionalBuilder is a re-implementation of Rack::Builder 
    with an added feature: each directive (use/run/map) is paired with 
    conditional logic.  This gives you the power of a dynamic Rack stack. 
    Each middleware, for example, can easily be conditionally toggled on 
    or off based on the subdomain of the incoming request.
