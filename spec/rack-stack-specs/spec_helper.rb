require "rspec"
require "rack-stack"
require "rack/test"

# TODO move all of this content into supporting files

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
  attr_accessor :name

  def initialize(name = nil, &block)
    self.name = name
    @block = block
  end

  def to_s
    "#{self.class.name}<#{name || object_id}>"
  end

  def call(env)
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    if @block
      if @block.arity <= 0
        response.instance_eval(&@block)
      elsif @block.arity == 1
        @block.call(response)
      else
        @block.call(request, response)
      end
    end
    response.finish
  end
end

# NamedMiddleware is a middleware that has a name and does nothing.
# Just for testing / debugging.
class NamedMiddleware
  attr_accessor :name

  def initialize(app, name = nil)
    @app = app
    self.name = name
  end

  def to_s
    "#{self.class.name}<#{name || object_id}>"
  end

  def call(env)
    @app.call(env)
  end
end
