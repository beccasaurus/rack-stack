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
  include Component
  include IndifferentEval

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

  # When enabled, RackStack behaves more like Rack::Builder (for compatibility).
  # Could be useful for adding RackStack functionality to existing Rack::Builder rackups.
  def self.rack_builder_compatibility
    @rack_builder_compatibility = false if @rack_builder_compatibility.nil?
    @rack_builder_compatibility
  end

  def self.rack_builder_compatibility=(value)
    @rack_builder_compatibility = value
  end

  # TODO document these use/map/run
  def self.use(*args, &block)
    RackStack::Use.new(*args, &block)
  end
  def self.map(*args, &block)
    RackStack::Map.new(*args, &block)
  end
  def self.run(*args, &block)
    RackStack::Run.new(*args, &block)
  end

  # Default Rack application that will be called if no Rack endpoint is found for a request.
  #
  # @note When RackStack is used as a Rack middleware, this is the application that 
  #   the middleware will `#call` if no matching endpoint is found in the RackStack.
  attr_accessor :default_app

  # Instantiates a new {RackStack}.
  # @param [#call] default_app Default application to `#call` if no other matching Rack endpoint is found ({#default_app}).
  def initialize(*args, &block)
    self.default_app = args.shift if args.first.respond_to?(:call)
    add_request_matcher args.first[:when] if args.first
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
    indifferent_eval &block
  end

  # Returns an Array of objects representing Rack applications/components.
  #
  # @note This Array may be manipulated manually, but only {Use}, {Run}, and
  #   {Map} objects are allowed.
  #
  # @see Use 
  # @see Run
  # @see Map
  def stack
    @stack ||= []
  end

  # Standard Rack application `#call` implementation.
  #
  # @raises NoMatchingApplicationError ... TODO yardoc for raise documentation?
  #
  # @note ... TODO ... if there's atleast 1 #map, 404/Not Found returned instead (for URLMap compatibility)
  def call(env)
    return default_response(env) unless matches?(env)
    Responder.new(self, env).finish
  end

  # Returns a Rack application/endpoint for this RackStack.
  # @note This is implemented for Rack::Builder compatibility only.
  # @raise [RuntimeError] If this RackStack contains no application (eg. only middleware), an exception will be raised.
  def to_app
    fail "missing run or map statement" if stack.all? {|component| component.is_a? Use }
    self
  end

  # Add the provided Rack middleware to the {#stack}.
  #
  # See {RackStack.use RackStack::use} for parameter documentation.
  def use(*args, &block)
    add_to_stack Use.new(*args, &block)
  end

  # Adds a nested {RackStack} to the {#stack} that is only evaluated when the given
  # path/url is matched.  This is intended to be compatible with `Rack::URLMap`.
  #
  # See {RackStack.map RackStack::map} for parameter documentation.
  def map(*args, &block)
    add_to_stack Map.new(*args, &block)
  end

  # Add the provided Rack endpoint to the {#stack}.
  #
  # See {RackStack.run RackStack::run} for parameter documentation.
  def run(*args)
    add_to_stack Run.new(*args)
  end

  # Returns the Rack object in this {RackStack} with the given name, if any.
  #
  # @example
  #   rack_stack.run :foo, @rack_app
  #
  #   rack_stack.get :foo # will return @rack_app
  # @example
  #   rack_stack.use :foo, MiddlewareClass
  #
  #   rack_stack.get :foo # will return instance of MiddlewareClass RackStack uses to process requests
  # @example
  #   rack_stack.map :foo, "/path" do
  #     run :app_inside_map, @foo_app
  #   end
  #
  #   rack_stack.get :foo # will return RackStack instance representing map block
  #
  #   rack_stack.get(:foo).get(:app_inside_map) # Works because :foo is the inner RackStack
  #   rack_stack[:foo][:app_inside_map]         # Works thanks to our [] alias
  #   rack_stack.foo.app_inside_map             # Works thanks to our method_missing implementation
  def get(name, &block)
    instance = get_instance(name)
    indifferent_eval(instance, &block) if instance
    instance
  end

  alias [] get

  # Removes every Rack application/component in the {#stack} with the given name.
  def remove(name)
    stack.reject! {|app| name == app.name }
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
    get(name, &block) || super
  end

  # Implemented as a counter part to our {#method_missing} implementation.
  # @see #method_missing
  def respond_to?(name)
    !! get(name)
  end

  # @api private
  # If this RackStack's request matchers don't match the a request, this will be used.
  # If the Responder fails to find a matching application for a request, this will be used.
  def default_response(env)
    return default_app.call(env) if default_app

    if RackStack.rack_builder_compatibility
      if is_a?(Map) || stack.any? {|component| component.is_a?(Map) }
        return [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{env["PATH_INFO"]}"]]
      end
    end

    raise NoMatchingApplicationError.new(:rack_stack => self, :env => env)
  end

  # Returns a string representation of this RackStack (for debugging).
  #
  # @example
  #   rack_stack = RackStack.new when: { host: "foo.com" } do
  #     use MiddlewareClass, "some args"
  #     map "/foo" do
  #       run FooApp.new
  #     end
  #     run MainApp.new
  #   end
  #
  #   puts rack_stack.trace
  #
  #   # Output of printing #trace below:
  #
  #   # RackStack.new when: [{:host=>"foo.com"}] do
  #   #   use MiddlewareClass, "some args"
  #   #   map "/Y" do
  #   #     run <result of FooApp.to_s>
  #   #   end
  #   #   run <result of MainApp.to_s>
  #   # end
  #
  def trace
    traced = "RackStack.new"
    traced << " default_app: #{default_app.inspect}" if default_app
    traced << " when: #{matchers_to_trace.inspect}" if matchers_to_trace.any?
    traced << " do\n"
    traced << stack.map(&:trace).join.gsub(/^/, "  ")
    traced << "end\n"
    traced
  end

  private

  def add_to_stack(app)
    case app
    when Run
      stack.push app
    when Map
      stack.insert index_for_next_urlmap(app), app
    when Use
      if non_middleware = stack.index {|a| not a.is_a? Use }
        stack.insert non_middleware, app
      else
        stack.push app
      end
    end
  end

  def get_instance(name)
    if component = stack.detect {|a| name == a.name }
      return component.instance
    end

    nested_rack_stacks.each do |rack_stack|
      return component if component = rack_stack.get(name)
    end
  end

  def index_for_next_urlmap(app)
    stack.each_with_index do |component, i|
      if component.is_a? Run
        return i
      elsif component.is_a? Map
        return i if app.location.length > component.location.length
      end
    end
    stack.length
  end

  def nested_rack_stacks
    stack.select {|component| component.is_a?(RackStack) }
  end
end
