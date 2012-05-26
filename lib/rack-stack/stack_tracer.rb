class RackStack

  # @api private
  # TODO kill this?  or maybe officially support #trace methods on all of our objects (mainly RackStack) ... ?
  class StackTracer

    def initialize(stack)
      @stack = stack
    end

    def trace
      @input = StringIO.new
      @stack.each { |app| trace_app(app) }
      @input.string
    end

    private

    def trace_app(app)
      case app
      when Middleware  then trace_middleware(app)
      when URLMap         then trace_map(app)
      when Endpoint then trace_application(app)
      end
    end

    def trace_middleware(app)
      matchers = app.request_matchers.select(&:trace).map(&:matcher)

      @input << "use"
      @input << " #{app.name.inspect}," if app.name
      @input << " #{app.middleware_class}"
      @input << ", #{app.arguments.map(&:inspect).join(', ')}" if app.arguments.any?
      @input << ", &#{app.block}" if app.block
      @input << ", when: #{matchers.inspect}" if matchers.any?
      @input << "\n"
    end
    
    def trace_map(app)
      matchers = app.request_matchers.select(&:trace).map(&:matcher)

      @input << "map"
      @input << " #{app.name.inspect}," if app.name
      @input << " #{app.location.inspect}"
      @input << ", when: #{matchers.inspect}" if matchers.any?
      @input << " do\n"
      @input << StackTracer.new(app.rack_stack.stack).trace.gsub(/^/, "  ") # TODO share input?
      @input << "end\n"
    end

    def trace_application(app)
      matchers = app.request_matchers.select(&:trace).map(&:matcher)

      @input << "run"
      @input << " #{app.name.inspect}," if app.name
      @input << " #{app.application}"
      @input << ", when: #{matchers.inspect}" if matchers.any?
      @input << "\n"
    end
  end
end
