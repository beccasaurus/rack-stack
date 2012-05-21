class RackStack
  class RackApplication < RackComponent
    attr_accessor :application

    def initialize(application, options = nil)
      @application = application
      add_request_matcher options[:when] if options
    end

    def call(env)
      @application.call(env)
    end
  end
end
