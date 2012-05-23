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
      !! get_match(env) && super
    end

    def call(env)
      match = get_match(env)

      env["SCRIPT_NAME"] = env["SCRIPT_NAME"] + path
      env["PATH_INFO"] = match[1]

      rack_stack.call(env)
    end

    def get_match(env)
      pattern = Regexp.new("^#{Regexp.quote(path.chomp("/")).gsub('/', '/+')}(.*)", nil, 'n')
      pattern.match env["PATH_INFO"]
    end
  end
end
