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
  #
  # TODO DRY this up with Responder#finish (?) ... same logic ... where should the 404 bits really be anyway?  It's URLMap specific ...
  def call(env)
    if matches?(env)
      Responder.new(self, env).finish
    elsif default_app
      default_app.call(env)
    else
      if stack.any? {|component| component.is_a? Map }
        [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{env["PATH_INFO"]}"]]
      else
        raise NoMatchingApplicationError.new(:rack_stack => self, :env => env)
      end
    end
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
    app = get_app_by_name(name)
    indifferent_eval(app, &block) if app
    app
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

  # Returns a string representation of this RackStack (for debugging).
  #
  # @example
  #   rack_stack = RackStack.new do
  #     # TODO finish this documentation after implementing :when on RackStack and then updating #trace to be wrapped with RackStack.new do ... NOTE also consider a RackStack with a :name (?) ... Hmm ... leads further down the path towards URLMap being just a RackStack with a particular configuration ... but, on the other hand, it has odd behavior ... hmm ...
  #   end
  #
  #   puts rack_stack.trace
  #   
  #   RackStack.new do # TODO wrap trace with this (show "RackStack.new" line so we can trace :default_app and :when)
  #     use X
  #     map "/Y"
  #     run Z
  #   end
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

  def get_app_by_name(name)
    if app = stack.detect {|app| name == app.name }
      case app
      when Use then return app.middleware
      when Map then return app
      when Run then return app.application
      end
    end

    nested_rack_stacks.each do |rack_stack|
      return app if app = rack_stack.get(name)
    end
  end

  def index_for_next_urlmap(app)
    stack.each_with_index do |stack_app, i|
      if stack_app.is_a? Run
        return i
      elsif stack_app.is_a? Map
        return i if app.location.length > stack_app.location.length
      end
    end
    stack.length
  end

  def nested_rack_stacks
    stack.select {|component| component.is_a?(RackStack) }
  end
end
