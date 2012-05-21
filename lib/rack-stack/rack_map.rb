class RackStack
  class RackMap
    attr_accessor :path, :rack_stack

    def initialize(path, default_app, &block)
      @path = path
      @rack_stack = RackStack.new(default_app) # do we need ?
      @rack_stack.instance_eval(&block) # NOTE: if arity, outer_env ... handle?
    end

    def matches?(env)
      @path == $1 if env["PATH_INFO"] =~ %r{^(/[^/]*)}
    end

    def call(env)
      @rack_stack.call(env)
    end
  end
end
