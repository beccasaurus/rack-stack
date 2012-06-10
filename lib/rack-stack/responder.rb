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
      elsif @rack_stack.default_app
        @rack_stack.default_app.call(@env)
      else
        if @rack_stack.stack.any? {|app| app.is_a? URLMap } # For Rack::Builder URLMap compatibility
          [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{@env["PATH_INFO"]}"]]
        else
          raise NoMatchingApplicationError.new(:rack_stack => @rack_stack, :env => @env)
        end
      end
    end
  end
end
