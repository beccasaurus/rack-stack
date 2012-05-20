require "rack-stack"
require "rack/builder"

# RackStack should be fully support the Rack::Builder API.
Rack::Builder = RackStack

require "bacon"
Bacon.const_set :RestrictName, Regexp.new(ENV["MATCH"]) if ENV["MATCH"]
Bacon.summary_on_exit
load File.dirname(__FILE__) + "/rack_builder_spec.rb"
