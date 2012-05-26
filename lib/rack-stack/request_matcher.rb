class RackStack

  # TODO add RequestMatcher documentation to this!
  # @api private
  class RequestMatcher
    attr_accessor :matcher

    def initialize(matcher)
      self.matcher = matcher
    end

    def result(env)
      request = Rack::Request.new(env)

      if @matcher.respond_to?(:call)
        if @matcher.respond_to?(:arity) && @matcher.arity <= 0
          # -> { host =~ /twitter.com/ }
          request.instance_eval(&@matcher)
        else
          # ->(request){ request.host =~ /twitter.com/ }
          @matcher.call(request)
        end
      else
        # { host: /twitter.com/ }
        # ["host", /twitter.com/]
        @matcher.all? do |request_attribute, value|
          value === request.send(request_attribute)
        end
      end
    end
  end
end
