require "rack"
require "stringio"

class RackStack

  attr_accessor :stack

  def initialize(default_app = nil, &block)
    @default_app = default_app
    @stack = []
    configure &block
  end

  def configure(&block)
    if block
      if block.arity <= 0
        instance_eval &block
      else
        block.call self
      end
    end
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

  def sort_stack!
    @stack = @stack.sort_by do |layer|
      [RackMiddleware, RackMap, RackApplication].index layer.class
    end
  end

  def to_app
    fail "missing run or map statement" if stack.all? {|app| app.is_a? RackMiddleware }
    self
  end

  def call(env)
    sort_stack! # instead, insert apps into stack where we want via #use/#map/#run ? DEF remove this from every #call.
    StackResponder.new(stack, @default_app, env).finish
  end

  def use(klass, *args, &block)
    @stack << RackMiddleware.new(klass, *args, &block)
  end

  # TODO add test for "map '/' do |outer_env|" to make sure outer_env is available in block
  def map(path, &block)
    @stack << RackMap.new(path, @default_app, &block)
  end

  def run(application, options = nil)
    @stack << RackApplication.new(application, options)
  end

  def trace
    StackTracer.new(stack).trace
  end

  class NoMatchingApplicationError < StandardError
    attr_accessor :stack, :env

    def initialize(attributes = {})
      self.stack = attributes[:stack]
      self.env = attributes[:env]
    end
  end

  class RackApplication
    attr_accessor :application, :if_condition, :unless_condition

    def initialize(application, options = nil)
      @application = application
      if options
        @if_condition = options[:if]
        @unless_condition = options[:unless]
      end
    end

    def call(env)
      @application.call(env)
    end

    def matches?(env)
      if @if_condition
        evaluate_condition(env, @if_condition)
      elsif @unless_condition
        ! evaluate_condition(env, @unless_condition)
      else
        true
      end
    end

    def evaluate_condition(env, condition)
      request = Rack::Request.new(env)

      if condition.is_a? Proc
        if condition.arity <= 0
          !! request.instance_eval(&condition)
        else
          !! condition.call(request)
        end
      else
        raise "Unknown condition type: #{condition.inspect}"
      end
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

  class StackResponder
    def initialize(stack, default_app, env)
      @stack = stack
      @default_app = default_app
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
      elsif @default_app
        @default_app.call(@env)
      else
        raise NoMatchingApplicationError.new(:stack => @stack, :env => @env)
      end
    end
  end

  class StackTracer
    def initialize(stack)
      @stack = stack
    end

    def trace
      @input = StringIO.new
      @stack.each { |app| trace_app(app) }
      @input.string
    end

    private

    def trace_app(app)
      case app
      when RackMiddleware  then trace_middleware(app)
      when RackMap         then trace_map(app)
      when RackApplication then trace_application(app)
      end
    end

    def trace_middleware(app)
      @input << "use #{app.middleware_class}, #{app.arguments.inspect}, &#{app.block.inspect}\n"
    end
    
    def trace_map(app)
      @input << "map #{app.path.inspect} do\n"
      @input << StackTracer.new(app.rack_stack.stack).trace.gsub(/^/, "  ") # TODO share input?
      @input << "end\n"
    end

    def trace_application(app)
      @input << "run #{app.application}\n"
    end
  end

end

require "rack-stack/version"
