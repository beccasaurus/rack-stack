class RackStack

  # TODO rename to just: RackStack::Responder.
  # @api private
  # Walks down a stack, calling all Rack applications (middlewares/endpoints) that match this request.
  # Responsible for generating a single response for a request sent to RackStack.
  class StackResponder
    def initialize(stack, default_app, env) # TODO go ahead and couple this to RackStack ... we want it please!
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
        if @stack.any? {|app| app.is_a? URLMap } # TODO check this logic ... when do we want to return these 404s?
          [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{@env["PATH_INFO"]}"]]
        else
          raise NoMatchingApplicationError.new(:stack => @stack, :env => @env) # TODO this should have the RackStack
        end
      end
    end
  end
end
