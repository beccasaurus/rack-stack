class RackStack

  # Represents any layer in a RackStack, eg. RackApplication, RackMiddleware,
  # or RackMap (could be just a RackApplication that has an extra RequestMatcher?)
  class RackComponent
    attr_accessor :name, :request_matchers

    def request_matchers
      @request_matchers ||= []
    end

    def add_request_matcher(matcher)
      if matcher
        matcher = RequestMatcher.new(matcher) unless matcher.is_a?(RequestMatcher)
        request_matchers << matcher
      end
    end

    def matches?(env)
      request_matchers.all? {|matcher| matcher.result(env) }
    end
  end
end
