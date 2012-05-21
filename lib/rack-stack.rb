require "rack"
require "stringio"

# ...
class RackStack

  ## Custom Exception Classes

  class NoMatchingApplicationError < StandardError
    attr_accessor :stack, :env

    def initialize(attributes = {})
      self.stack = attributes[:stack]
      self.env = attributes[:env]
    end
  end

  ## RackStack

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

  def sort_stack!
    @stack = @stack.sort_by do |layer|
      [RackMiddleware, RackMap, RackApplication].index layer.class
    end
  end

  def to_app
    fail "missing run or map statement" if stack.all? {|app| app.is_a? RackMiddleware }
    self
  end

  # Rack::Builder: call(env)
  def call(env)
    sort_stack! # instead, insert apps into stack where we want via #use/#map/#run ? DEF remove this from every #call.
    StackResponder.new(stack, @default_app, env).finish
  end

  # Rack::Builder: use(middleware, *args, &block)
  def use(klass, *args, &block)
    @stack << RackMiddleware.new(klass, *args, &block)
  end

  # Rack::Builder: map(path, &block)
  # TODO add test for "map '/' do |outer_env|" to make sure outer_env is available in block
  def map(path, &block)
    @stack << RackMap.new(path, @default_app, &block)
  end

  # Rack::Builder: run(app)
  def run(application, options = nil)
    @stack << RackApplication.new(application, options)
  end

  def trace
    StackTracer.new(stack).trace
  end
end

require "rack-stack/version"
require "rack-stack/rack_component"
require "rack-stack/rack_application"
require "rack-stack/rack_map"
require "rack-stack/rack_middleware"
require "rack-stack/request_matcher"
require "rack-stack/stack_responder"
require "rack-stack/stack_tracer"
