class RackStack

  # @api private
  # Represents any type of Rack application in a RackStack, eg. Endpoint, Middleware, or URLMap
  class Application

    # Application name (optional).
    attr_accessor :name
    
    # List of all RequestMatcher to run for see if this 
    # application #matches? a given request
    def request_matchers
      @request_matchers ||= []
    end

    # Adds the given matcher to #request_matchers
    def add_request_matcher(matcher, options = nil)
      trace = options && options.has_key?(:trace) ? options[:trace] : true
      if matcher
        matcher = RequestMatcher.new(matcher, trace) unless matcher.is_a?(RequestMatcher)
        request_matchers << matcher
      end
    end

    # Returns true if all #request_matchers match the current request
    def matches?(env)
      request_matchers.all? {|matcher| matcher.result(env) }
    end
  end
end
