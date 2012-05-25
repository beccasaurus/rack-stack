# Represents a stack of Rack applications, eg. middleware, endpoints, and maps
class RackStack

  def self.app(default_app = nil, &block)
    new(default_app, &block).to_app
  end

  def self.parse_file(file_path)
    return load_from(file_path), :debug => true # XXX for Rack::Builder compatibility spec
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

  # Returns RackStack object representing a Rack middleware that can be added to the #stack
  def self.use(*args, &block)
    name = args.shift if args.first.is_a?(Symbol)
    klass = args.shift
    Middleware.new(name, klass, *args, &block)
  end

  # Returns RackStack object representing a Rack endpoint that can be added to the #stack
  def self.run(*args)
    name = args.shift if args.first.is_a?(Symbol)
    application = args.shift
    options = args.shift
    Endpoint.new(name, application, options)
  end

  # Returns RackStack object representing a Rack URLMap that can be added to the #stack
  def self.map(*args, &block)
    name = args.shift if args.first.is_a?(Symbol)
    path = args.shift
    options = args.shift
    URLMap.new(name, path, options, &block)
  end

  # Returns an Array of RackStack objects
  # @see RackStack::use 
  # @see RackStack::run
  # @see RackStack::run
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

  def call(env)
    StackResponder.new(stack, @default_app, env).finish
  end

  def to_app
    fail "missing run or map statement" if stack.all? {|app| app.is_a? Middleware }
    self
  end

  def use(*args, &block)
    @stack << self.class.use(*args, &block)
    stack_updated!
  end

  def map(*args, &block)
    @stack << self.class.map(*args, &block)
    stack_updated!
  end

  def run(*args)
    @stack << self.class.run(*args)
    stack_updated!
  end

  def [](name)
    if app = @stack.detect {|app| name == app.name }
      return app.application
    end

    nested_rack_stacks.each do |rack_stack|
      return app if app = rack_stack[name]
    end
  end

  def remove(name)
    @stack.reject! {|app| name == app.name }
    nested_rack_stacks.each {|rack_stack| rack_stack.remove(name) }
  end

  def stack_updated!
    sort_stack!
  end

  def method_missing(name, *args, &block)
    app = self[name] if args.empty? && block.nil?
    app || super
  end

  def respond_to?(name)
    !! self[name]
  end

  def trace
    StackTracer.new(stack).trace
  end

  private

  def sort_stack!
    @stack = @stack.sort_by do |layer|
      # We assume a certain stack order.  #use, #map, #run
      class_value = [Middleware, URLMap, Endpoint].index(layer.class)

      # We order every #map by the length of its location (longest first)
      map_location_value = layer.is_a?(URLMap) ? (-layer.location.length) : 0

      [class_value, map_location_value]
    end
  end

  def nested_rack_stacks
    @stack.select {|app| app.is_a? URLMap }.map {|map| map.rack_stack }
  end
end
