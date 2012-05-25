class RackStack
  class StackResponder
    def initialize(stack, default_app, env)
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
        if @stack.any? {|app| app.is_a? RackMap }
          [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{@env["PATH_INFO"]}"]]
        else
          raise NoMatchingApplicationError.new(:stack => @stack, :env => @env)
        end
      end
    end
  end
end
