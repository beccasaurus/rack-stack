require "rspec"
require "rack-stack"
require "rack/test"

# Helper for building little Rack applications.
#
#   simple_app { write "Hello" }
#   simple_app {|response| response.write "Hello" }
#   simple_app {|request, response| response.write "You requested #{request['PATH_INFO']}" }
#
def simple_app(&block)
  lambda {|env|
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    if block.arity <= 0
      response.instance_eval(&block)
    elsif block.arity == 1
      block.call(response)
    else
      block.call(request, response)
    end
    response.finish
  }
end
