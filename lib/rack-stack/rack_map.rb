class RackStack
  class RackMap < RackComponent
    attr_accessor :path, :rack_stack

    def initialize(path, default_app, options = nil, &block)
      self.path = path
      self.rack_stack = RackStack.new(default_app) # do we need ?
      self.rack_stack.instance_eval(&block) # NOTE: if arity, outer_env ... handle?

      add_request_matcher options[:when] if options
    end

    def matches?(env)
      path_matches?(env) && super
    end

    def path_matches?(env)
      path == $1 if env["PATH_INFO"] =~ %r{^(/[^/]*)}
    end

    def call(env)
      rack_stack.call(env)
    end
  end
end
