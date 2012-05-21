class RackStack
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
      when RackMiddleware  then trace_middleware(app)
      when RackMap         then trace_map(app)
      when RackApplication then trace_application(app)
      end
    end

    def trace_middleware(app)
      @input << "use #{app.middleware_class}, #{app.arguments.inspect}, &#{app.block.inspect}\n"
    end
    
    def trace_map(app)
      @input << "map #{app.path.inspect} do\n"
      @input << StackTracer.new(app.rack_stack.stack).trace.gsub(/^/, "  ") # TODO share input?
      @input << "end\n"
    end

    def trace_application(app)
      @input << "run #{app.application}\n"
    end
  end
end
