class RackStack
  class RackApplication
    attr_accessor :application, :if_condition, :unless_condition

    def initialize(application, options = nil)
      @application = application
      if options
        @if_condition = options[:if]
        @unless_condition = options[:unless]
      end
    end

    def call(env)
      @application.call(env)
    end

    def matches?(env)
      if @if_condition
        evaluate_condition(env, @if_condition)
      elsif @unless_condition
        ! evaluate_condition(env, @unless_condition)
      else
        true
      end
    end

    def evaluate_condition(env, condition)
      request = Rack::Request.new(env)

      if condition.is_a? Proc
        if condition.arity <= 0
          !! request.instance_eval(&condition)
        else
          !! condition.call(request)
        end
      else
        raise "Unknown condition type: #{condition.inspect}"
      end
    end
  end
end
