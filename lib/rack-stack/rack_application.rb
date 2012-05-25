class RackStack
  class RackApplication < RackComponent
    attr_accessor :application

    def initialize(name, application, options = nil)
      self.name = name
      self.application = application

      add_request_matcher options[:when] if options
    end

    def call(env)
      application.call(env)
    end
  end
end
