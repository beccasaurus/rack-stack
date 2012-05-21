require "spec_helper"

class RackStack
  describe RequestMatcher do

    def env_for(*args)
      Rack::MockRequest.env_for(*args)
    end

    it "when: -> { host =~ /twitter.com/ }" do
      matcher = RequestMatcher.new lambda { host =~ /twitter.com/ }

      matcher.result(env_for "http://www.twitter.com/").should be_true
      matcher.result(env_for "http://www.different.com/").should be_false
    end

    it "when: ->(request) { request.host =~ /twitter.com/ }" do
      matcher = RequestMatcher.new lambda {|request| request.host =~ /twitter.com/ }

      matcher.result(env_for "http://www.twitter.com/").should be_true
      matcher.result(env_for "http://www.different.com/").should be_false
    end

    it "when: { host: /twitter.com/ }" do
      matcher = RequestMatcher.new :host => /twitter.com/

      matcher.result(env_for "http://www.twitter.com/").should be_true
      matcher.result(env_for "http://www.different.com/").should be_false
    end
  end
end
