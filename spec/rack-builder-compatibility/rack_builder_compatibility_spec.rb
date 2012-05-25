require "rack-stack"
require "rack/builder"
require "rack/urlmap"

class UrlmapProxy
  def initialize(uris_to_apps)
    @rack_stack = RackStack.new
    uris_to_apps.each do |uri, app|
      @rack_stack.map uri do |o|
        o.run app
      end
    end
  end

  def call(env)
    @rack_stack.call(env)
  end
end

# RackStack should be fully support the Rack::Builder API.
Rack::Builder = RackStack

# UrlmapProxy lets us exercise our #map functionality by 
# running the tests for Rack::URLMap.
Rack::URLMap = UrlmapProxy

require "bacon"
Bacon.const_set :RestrictName, Regexp.new(ENV["MATCH"]) if ENV["MATCH"]
Bacon.summary_on_exit
load File.dirname(__FILE__) + "/rack_builder_spec.rb"
load File.dirname(__FILE__) + "/rack_urlmap_spec.rb"
