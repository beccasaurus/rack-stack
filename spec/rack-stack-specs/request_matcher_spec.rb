require "spec_helper"

describe RackStack::RequestMatcher do

  def env_for(*args)
    Rack::MockRequest.env_for(*args)
  end

  it "when: -> { host =~ /twitter.com/ }" do
    matcher = RackStack::RequestMatcher.new(proc { host =~ /twitter.com/ })

    matcher.matches?(env_for "http://www.twitter.com/").should be_true
    matcher.matches?(env_for "http://www.different.com/").should be_false
  end

  it "when: ->(request) { request.host =~ /twitter.com/ }" do
    matcher = RackStack::RequestMatcher.new lambda {|request| request.host =~ /twitter.com/ }

    matcher.matches?(env_for "http://www.twitter.com/").should be_true
    matcher.matches?(env_for "http://www.different.com/").should be_false
  end

  it "when: { host: /twitter.com/ }" do
    matcher = RackStack::RequestMatcher.new :host => /twitter.com/

    matcher.matches?(env_for "http://www.twitter.com/").should be_true
    matcher.matches?(env_for "http://www.different.com/").should be_false
  end

end
