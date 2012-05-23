require "rspec"
require "rack-stack"
require "rack/test"

def clean_trace(trace, options = {})
  options[:indent] ||= 6
  trace.gsub(/^ {#{options[:indent]}}/, "").strip + "\n"
end

# Wraps the response text in provided text (default: "*")
class ResponseWrapperMiddleware
  def initialize(app, text = "*", options = nil)
    @app = app
    @text = text
    @options = options || {}
    @options[:times] ||= 1
  end

  def text
    @text * @options[:times]
  end

  def call(env)
    status, headers, body_parts = @app.call(env)
    body = ""
    body_parts.each {|part| body << part }
    body = "#{text}#{body}#{text}"
    headers["Content-Length"] = body.length.to_s
    [status, headers, [body]]
  end
end

# Helper for building little Rack applications.
#
#   simple_app { write "Hello" }
#   simple_app {|response| response.write "Hello" }
#   simple_app {|request, response| response.write "You requested #{request['PATH_INFO']}" }
#
def simple_app(name = nil, &block)
  SimpleApp.new(name, &block)
end

class SimpleApp
  def initialize(name = nil, &block)
    @name = name
    @block = block
  end

  def to_s
    "SimpleApp<#{@name || object_id}>"
  end

  def call(env)
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    if @block.arity <= 0
      response.instance_eval(&@block)
    elsif @block.arity == 1
      @block.call(response)
    else
      @block.call(request, response)
    end
    response.finish
  end
end
