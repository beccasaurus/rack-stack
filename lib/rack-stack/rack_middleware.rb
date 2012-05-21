class RackStack
  class RackMiddleware < RackComponent
    attr_accessor :middleware_class, :arguments, :block

    def initialize(middleware_class, *arguments, &block)
      self.middleware_class = middleware_class
      self.arguments = arguments
      self.block = block
    end

    def update_application(rack_application)
      @middleware = middleware_class.new(rack_application, *arguments, &block)
    end

    def call(env)
      @middleware.call(env)
    end
  end
end
