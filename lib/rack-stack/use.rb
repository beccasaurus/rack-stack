class RackStack

  # @api private
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
  #
  class Use
    include Component

    attr_accessor :middleware_class, :arguments, :block, :middleware, :application

    def initialize(*args, &block)
      self.name = args.shift if args.first.is_a?(Symbol)
      self.middleware_class = args.shift
      self.arguments = args
      self.block = block
      read_options_from_arguments!
      inner_app = lambda {|env| application.call(env) }
      self.middleware = middleware_class.new(inner_app, *arguments, &block)
    end

    def use?
      true
    end

    def update_application(rack_application)
      self.application = rack_application
    end

    def call(env)
      self.middleware.call(env)
    end

    def trace
      traced = "use"
      traced << " #{name.inspect}," if name
      traced << " #{middleware_class}"
      traced << ", #{arguments.map(&:inspect).join(', ')}" if arguments.any?
      traced << ", &#{block}" if block
      traced << ", when: #{matchers_to_trace.inspect}" if matchers_to_trace.any?
      traced << "\n"
      traced
    end

    def instance
      middleware
    end

    private

    def read_options_from_arguments!
      if arguments.last.is_a?(Hash)
        if arguments.last.has_key?(:when)
          add_request_matcher arguments.last.delete(:when)
          arguments.pop if arguments.last.empty?
        end
      end
    end
  end
end
