class RackStack

  # @api private
  # Represents a Rack endpoint (eg. added via #run)
  class Endpoint < Application

    # The actual Rack application (instance) to run
    attr_accessor :application

    def initialize(name, application, options = nil)
      self.name = name
      self.application = application

      add_request_matcher options[:when] if options
    end

    # Calls the Rack application
    def call(env)
      application.call(env)
    end
  end
end
