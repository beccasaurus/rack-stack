# Helper for building little Rack applications.
#
# @example
#
#   # No arguments: the block is evaluated on a Rack::Response
#   SimpleApp.new { write "Hello" }
#
#   # 1 argument: a Rack::Response is yielded to the block
#   SimpleApp.new {|response| response.write "Hello" }
#
#   # 2 arguments: a the incoming request's Rack::Request and a Rack::Response are yielded to the block
#   SimpleApp.new {|request, response| response.write "You requested #{request['PATH_INFO']}" }
#
class SimpleApp

  attr_accessor :name, :block

  def initialize(name = nil, &block)
    self.name = name
    self.block = block
  end

  def to_s
    "#{self.class.name}<#{name || object_id}>"
  end

  def call(env)
    request = Rack::Request.new(env)
    response = Rack::Response.new

    if block
      if block.arity <= 0
        response.instance_eval(&block)
      elsif block.arity == 1
        block.call(response)
      else
        block.call(request, response)
      end
    end

    response.finish
  end

end
