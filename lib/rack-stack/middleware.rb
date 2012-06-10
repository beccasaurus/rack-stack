class RackStack

  # @api private
  # Represents a Rack middleware (eg. added via #use)
  class Middleware
    include Component

    attr_accessor :middleware_class, :arguments, :block, :middleware, :application

    def initialize(name, middleware_class, *arguments, &block)
      self.name = name
      self.middleware_class = middleware_class
      self.arguments = arguments
      self.block = block
      read_options_from_arguments!
      inner_app = lambda {|env| application.call(env) }
      self.middleware = middleware_class.new(inner_app, *arguments, &block)
    end

    def update_application(rack_application)
      self.application = rack_application
    end

    def call(env)
      self.middleware.call(env)
    end

    def trace
      matchers = request_matchers.select(&:trace).map(&:matcher)

      traced = ""
      traced << "use"
      traced << " #{name.inspect}," if name
      traced << " #{middleware_class}"
      traced << ", #{arguments.map(&:inspect).join(', ')}" if arguments.any?
      traced << ", &#{block}" if block
      traced << ", when: #{matchers.inspect}" if matchers.any?
      traced << "\n"
      traced
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
