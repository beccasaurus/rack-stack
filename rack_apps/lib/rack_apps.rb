require "forwardable"

# ...
class RackApps

  class Router
    extend Forwardable

    attr_accessor :routes

    def_delegator :routes, :push, :each

    def initialize
      self.routes = []
    end

    def add_route_test
      match :twitter => @rackapp, :host => "api.twitter.com"
      match twitter: @rackapp, host: "api.twitter.com"

      # shortcut for ...
      match :rack_application => @x, :application_name => ""
      # ... or just :app or something ...
    end

    class Route
      attr_accessor :conditions, :application_name, :rack_application
    end
  end

  attr_accessor :router

  def initialize
    self.router = Router.new
  end

  def add(name, conditions)
    app = conditions.delete(:app)
    router.push :name => name, :app => app, :conditions => conditions
  end

  def call(env)
    router.each do |entry|
      if matches_conditions?(env, entry[:conditions])
        return entry[:app].call(env)
      end
    end

    raise "No matching app found. URL: #{Rack::Request.new(env).url.inspect}"
  end

  def matches_conditions?(env, conditions)
    request = Rack::Request.new(env)
    conditions.all? do |key, value|
      value === request.send(key)
    end  
  end

end
