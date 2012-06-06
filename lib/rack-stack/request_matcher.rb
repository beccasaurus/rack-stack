class RackStack

  # TODO add RequestMatcher documentation to this!
  # @api private
  class RequestMatcher
    include IndifferentEval

    attr_accessor :matcher, :trace

    def initialize(matcher, trace = true)
      self.matcher = matcher
      self.trace = trace
    end

    def result(env)
      request = Rack::Request.new(env)

      if @matcher.respond_to?(:call)
        # -> { host =~ /twitter.com/ }
        # ->(request){ request.host =~ /twitter.com/ }
        indifferent_eval request, &@matcher
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
