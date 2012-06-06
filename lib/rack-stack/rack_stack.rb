# Represents a stack of Rack applications, eg. middleware, endpoints, and maps
#
# @example
#   RackStack.new do
#     use SomeMiddleware, when: ->(request){ request.path_info == "/foo" }
#
#     map "/foo", when: { host: /foo.com/ } do
#       use FooMiddleware
#       run FooApp.new
#     end
#
#     run SomeApp
#   end
class RackStack

  # Returns new {RackStack} initialized using the provided arguments.
  # @note {RackStack#to_app} is called on the {RackStack} instance before it is returned.
  def self.app(default_app = nil, &block)
    new(default_app, &block).to_app
  end

  # @api private
  # 
  # Alias for {RackStack.load_from}
  #
  # @note This is implemented for Rack::Builder compatibility only.
  #   Configuration option parsing is not supported.
  #   Use {RackStack.load_from} instead.
  def self.parse_file(file_path)
    return load_from(file_path),
      :debug => true # XXX for Rack::Builder compatibility spec
  end

  # Returns {RackStack} loaded from the given file.
  #
  # Unless the file extension is `.ru`, the file will be required and 
  # the class/module with the name of the file will be returned.
  #
  # If the file extension is `.ru`, the Ruby code in the file will be 
  # evaluated in a new RackStack block.  The resulting RackStack object 
  # will be returned.
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

  # Returns {RackStack} object representing a Rack middleware that can be added to the {#stack}.
  #
  # @example
  #   use MiddlewareClass
  # @example
  #   use MiddlewareClass, when: { path_info: "/foo" }
  # @example
  #   use :name, MiddlewareClass, when: { path_info: "/foo" }
  # @example
  #   use MiddlewareClass, arg1, arg2 do
  #     # this block and the arguments will be passed 
  #     # along to MiddlewareClass's constructor
  #   end
  def self.use(*args, &block)
    name = args.shift if args.first.is_a?(Symbol)
    klass = args.shift
    Middleware.new(name, klass, *args, &block)
  end

  # Returns object representing a Rack endpoint that can be added to the {#stack}.
  #
  # @example
  #   run RackApp.new
  # @example
  #   run RackApp.new, when: { path_info: "/foo" }
  # @example
  #   run :name, RackApp.new, when: { path_info: "/foo" }
  def self.run(*args)
    name = args.shift if args.first.is_a?(Symbol)
    application = args.shift
    options = args.shift
    Endpoint.new(name, application, options)
  end

  # Returns object representing a Rack URLMap that can be added to the #stack
  #
  # @example
  #   map "/path", when: { host: "some-host.com" } do
  #     use InnerMiddleware
  #     run CustomInnerApp.new, when: ->{ path_info =~ /custom/ }
  #     run InnerApp.new
  #   end
  def self.map(*args, &block)
    name = args.shift if args.first.is_a?(Symbol)
    path = args.shift
    options = args.shift
    URLMap.new(name, path, options, &block)
  end

  # Returns an Array of objects representing Rack applications/components.
  #
  # @note This Array may be manipulated manually, but all objects in the 
  #   stack must be wrapped via {RackStack.use}, {RackStack.run}, or {RackStack.map}.
  #
  # @see RackStack.use 
  # @see RackStack.run
  # @see RackStack.map
  attr_accessor :stack

  # TODO expose default_app as an attribute

  # Instantiates a new {RackStack}.
  # @param [#call] Default application to call if no other matching applications are found.
  def initialize(default_app = nil, &block)
    @default_app = default_app
    @stack = []
    configure &block
  end

  # Configures this RackStack using the provided block.
  #
  # @yield [nil, RackStack] If the given block has no arguments, it will be 
  #   `instance_eval`'d against this RackStack.  Alternatively, 1 block argument 
  #   may be used and we will call that block, yielding this RackStack instance.
  #
  # @note This is not 100% compatible with the behavior of blocks passed to Rack::Builder's constructor.
  #   Rack::Builder always calls instance_eval, even when a block argument is passed.
  def configure(&block)
    if block
      if block.arity <= 0
        instance_eval &block
      else
        block.call self
      end
    end
  end

  # RackStack instanced behave like Rack applications by implementing `#call(env)`
  def call(env)
    StackResponder.new(stack, @default_app, env).finish
  end

  # @api private
  #
  # Returns a Rack application/endpoint for this RackStack.
  #
  # @note This is implemented for Rack::Builder compatibility only.
  # @raise [RuntimeError] If this RackStack contains no application (eg. only middleware), an exception will be raised.
  def to_app
    fail "missing run or map statement" if stack.all? {|app| app.is_a? Middleware }
    self
  end

  # Add the provided Rack middleware to the {#stack}.
  #
  # See {RackStack.use RackStack::use} for parameter documentation.
  def use(*args, &block)
    add_to_stack self.class.use(*args, &block)
  end

  # Adds a nested {RackStack} to the {#stack} that is only evaluated when the given 
  # path/url is matched.  This is intended to be compatible with `Rack::URLMap`.
  #
  # See {RackStack.map RackStack::map} for parameter documentation.
  def map(*args, &block)
    add_to_stack self.class.map(*args, &block)
  end

  # Add the provided Rack endpoint to the {#stack}.
  #
  # See {RackStack.run RackStack::run} for parameter documentation.
  def run(*args)
    add_to_stack self.class.run(*args)
  end

  # Returns the Rack object in this {RackStack} with the given name, if any.
  #
  #  - If you `run :name, RackApplication.new`, `get(:name)` will return the `RackApplication` instance.
  #  - If you `use :name, RackMiddleware`, `get(:name)` will return ... (?) **Not Implemented Yet**
  #  - If you `map :name, "/path" do ... end`, `get(:name)` will return the `RackStack` instance. **Not Implemented Yet**
  #
  # @example
  #   # show 3 examples, 1 for each #run, use, map TODO
  def get(name) # TODO accept a block and (instance_eval || call) it (like we do on initialize) with the returned app.
    if app = @stack.detect {|app| name == app.name }
      case app
      when Middleware then return app.middleware
      when URLMap then return app.rack_stack
      when Endpoint then return app.application
      end
    end

    nested_rack_stacks.each do |rack_stack|
      return app if app = rack_stack.get(name)
    end
  end

  alias [] get

  # Removes every Rack application/component in the {#stack} with the given name.
  def remove(name)
    @stack.reject! {|app| name == app.name }
    nested_rack_stacks.each {|rack_stack| rack_stack.remove(name) }
  end

  # As a shortcut for {#get}, RackStack responds to method calls matching 
  # the name of a named stack component by returning that component.
  # 
  # @example
  #   rack_stack = RackStack.new do
  #     run :my_app, MyApplication.new
  #   end
  #
  #   rack_stack.my_app # => <MyApplication instance>
  #
  # @see #get
  def method_missing(name, *args, &block)
    app = get(name) if args.empty? && block.nil?
    app || super
  end

  # Implemented as a counter part to our {#method_missing} implementation.
  # @see #method_missing
  def respond_to?(name)
    !! get(name)
  end

  # @api private
  # Not currently publicly supported, this may be used to render a RackStack to string for debugging.
  def trace
    @stack.map(&:trace).join
  end

  private

  def add_to_stack(app)
    case app
    when Endpoint
      @stack.push app
    when URLMap
      @stack.insert index_for_next_urlmap(app), app
    when Middleware
      if non_middleware = @stack.index {|a| not a.is_a? Middleware }
        @stack.insert non_middleware, app
      else
        @stack.push app
      end
    end
  end

  def index_for_next_urlmap(app)
    @stack.each_with_index do |stack_app, i|
      if stack_app.is_a? Endpoint
        return i
      elsif stack_app.is_a? URLMap
        return i if app.location.length > stack_app.location.length
      end
    end
    @stack.length
  end

  def nested_rack_stacks
    @stack.select {|app| app.is_a? URLMap }.map {|map| map.rack_stack }
  end
end
