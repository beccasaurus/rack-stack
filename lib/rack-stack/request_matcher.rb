class RackStack

  class RequestMatcher
    def initialize(matcher)
      @matcher = matcher
    end

    def result(env)
      request = Rack::Request.new(env)

      if @matcher.is_a? Proc
        if @matcher.arity <= 0
          # -> { host =~ /twitter.com/ }
          request.instance_eval(&@matcher)
        else
          # ->(request){ request.host =~ /twitter.com/ }
          @matcher.call(request)
        end
      else
        # { host: /twitter.com/ }
        @matcher.all? do |request_attribute, value|
          value === request.send(request_attribute)
        end
      end
    end
  end
end
