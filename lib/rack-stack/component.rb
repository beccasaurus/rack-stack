class RackStack

  # Defines behavior required for an object to be included in {RackStack#stack}.
  module Component

    # Every RackStack::Component MAY have a name.
    #
    # Named components may be removed from a RackStack via {RackStack#remove}.
    #
    # Named components may be referenced from a RackStack via {RackStac#get}.
    attr_accessor :name

    # Every RackStack::Component MAY have request matchers (conditions).
    #
    # An array of {RequestMatcher}s associated with this component.
    attr_accessor :request_matchers

    def request_matchers
      @request_matchers ||= []
    end

    def matchers_to_trace
      request_matchers.select(&:trace).map(&:matcher)
    end

    # Returns true if all {#request_matchers} match the request.
    def matches?(env)
      request_matchers.all? {|matcher| matcher.matches?(env) }
    end

    # Adds the given request matcher to {#request_matchers}.
    def add_request_matcher(matcher = nil, trace = true)
      if matcher
        matcher = RequestMatcher.new(matcher, trace) unless matcher.is_a?(RequestMatcher)
        request_matchers << matcher
      end
    end

    # All component classes should override #instance to return the object that 
    # `RackStack#instance(:component_name)` should return.
    def instance
      raise NotImplementedError, "#{self.class.name} must implement #instance"
    end

    def run?
      false
    end

    def use?
      false
    end

    def map?
      false
    end
  end
end
