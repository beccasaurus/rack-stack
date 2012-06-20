class RackStack

  # @api private
  #
  # Responsible for generating a single response for a request sent to RackStack.
  #
  # Walks down a stack, calling all Rack applications (middlewares/endpoints)
  # that match this request.
  class Responder

    def initialize(rack_stack, env)
      @rack_stack = rack_stack
      @env = env
      @stack_level = 0
    end

    def next_application
      @rack_stack.stack[@stack_level]
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
        @rack_stack.default_response(@env)
      end
    end
  end
end
