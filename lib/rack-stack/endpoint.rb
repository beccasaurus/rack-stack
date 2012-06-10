class RackStack

  # @api private
  # Represents a Rack endpoint (eg. added via #run)
  class Endpoint
    include Component

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

    def trace
      matchers = request_matchers.select(&:trace).map(&:matcher)

      traced = ""
      traced << "run"
      traced << " #{name.inspect}," if name
      traced << " #{application}"
      traced << ", when: #{matchers.inspect}" if matchers.any?
      traced << "\n"
      traced
    end
  end
end
