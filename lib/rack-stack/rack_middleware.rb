class RackStack
  class RackMiddleware
    def initialize(middleware_class, *arguments, &block)
      @middleware_class = middleware_class
      @arguments = arguments
      @block = block
    end

    def update_application(rack_application)
      @middleware = @middleware_class.new(rack_application, *@arguments, &@block)
    end

    def call(env)
      @middleware.call(env)
    end

    def matches?(env)
      true
    end
  end
end
