class RackStack

  # @api private
  #
  # @example
  #   run RackApp.new
  # @example
  #   run RackApp.new, when: { path_info: "/foo" }
  # @example
  #   run :name, RackApp.new, when: { path_info: "/foo" }
  class Run
    include Component

    # The actual Rack application (instance) to run
    attr_accessor :application

    def initialize(*args)
      self.name = args.shift if args.first.is_a?(Symbol)
      self.application = args.shift
      add_request_matcher args.first[:when] if args.first
    end

    # Calls the Rack application
    def call(env)
      application.call(env)
    end

    def trace
      matchers = request_matchers.select(&:trace).map(&:matcher)

      traced = "run"
      traced << " #{name.inspect}," if name
      traced << " #{application}"
      traced << ", when: #{matchers.inspect}" if matchers.any?
      traced << "\n"
      traced
    end
  end
end
