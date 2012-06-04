class RackStack

  # @api private
  # Represents a Rack middleware (eg. added via #use)
  class Middleware < Application
    attr_accessor :middleware_class, :arguments, :block, :middleware

    def initialize(name, middleware_class, *arguments, &block)
      self.name = name
      self.middleware_class = middleware_class
      self.arguments = arguments
      self.block = block
      read_options_from_arguments!
    end

    # TODO when is this called again?  it's not clear.  can we rename this to something that'll make it obvious?  not "update application"
    def update_application(rack_application)
      self.middleware = middleware_class.new(rack_application, *arguments, &block)
    end

    def call(env)
      self.middleware.call(env)
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
