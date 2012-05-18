class RackStack

  def initialize(default_app = nil, &block)
    @default_app = nil
    @middleware = []
    @mappings = []
    @applications = []
    instance_eval &block
  end

  def self.app(default_app = nil, &block)
    new(default_app, &block).to_app
  end

  def self.parse_file(file_path)
    return load_from(file_path), :debug => true # for Rack::Builder specs
  end

  def self.load_from(file_path)
    if File.extname(file_path) == ".ru"
      source = File.read file_path
      source.sub!(/^__END__\n.*\Z/m, '')
      eval "RackStack.new {\n" + source + "\n}.to_app", TOPLEVEL_BINDING, file_path
    else
      require file_path
      Object.const_get File.basename(file_path, ".rb").capitalize
    end
  end

  def to_app
    fail "missing run or map statement" if stack.all? {|app| app.is_a? RackMiddleware }
    self
  end

  def call(env)
    StackResponder.new(stack, env).finish
  end

  def use(klass, *args, &block)
    @middleware << RackMiddleware.new(klass, *args, &block)
  end

  def map(path, &block)
    @mappings << RackMap.new(path, &block)
  end

  def run(application)
    @applications << RackApplication.new(application)
  end

  def stack
    @middleware + @mappings + @applications
  end

  class RackApplication
    def initialize(application)
      @application = application
    end

    def call(env)
      @application.call(env)
    end

    def matches?(env)
      true
    end
  end

  class RackMiddleware
    def initialize(middleware_class, *arguments, &block)
      @middleware_class = middleware_class
      @arguments = arguments
      @block = block
    end

    def update_application(rack_application)
      @middleware = @middleware_class.new(rack_application, *@arguments, &@block)
    end

    def call(env)
      @middleware.call(env)
    end

    def matches?(env)
      true
    end
  end

  class RackMap
    def initialize(path, &block)
      @path = path
      @rack_stack = RackStack.new(&block)
    end

    def matches?(env)
      @path == $1 if env["PATH_INFO"] =~ %r{^(/[^/]*)}
    end

    def call(env)
      @rack_stack.call(env)
    end
  end

  class StackResponder
    def initialize(stack, env)
      @stack = stack
      @env = env
      @stack_level = 0
    end

    def next_application
      @stack[@stack_level]
    end

    def next_matching_application
      @stack_level += 1 while next_application && ! next_application.matches?(@env)
      next_application
    end

    def call(env)
      @env = env
      finish
    end

    def finish
      if rack_application = next_matching_application
        @stack_level += 1
        rack_application.update_application(self) if rack_application.respond_to?(:update_application)
        rack_application.call(@env)
      else
        raise "Couldn't find a matching application for request #{Rack::Request.new(@env).url}.  Stack: \n#{@stack_level} #{@stack.inspect}"
      end
    end
  end

end

require "rack-stack/version"
