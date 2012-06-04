require "spec_helper"

class RackStack
  describe Application do

    def env_for(*args)
      Rack::MockRequest.env_for(*args)
    end

    it "has a #name (optional)" do
      application = Application.new
      application.name.should be_nil
      application.name = :usually_a_symbol
      application.name.should == :usually_a_symbol
    end

    it "has many #request_matchers (which determine #matches?(env))" do
      application = Application.new
      application.request_matchers.should be_empty
      application.matches?(env_for "http://anything.com").should be_true

      application.request_matchers << RequestMatcher.new(:host => /twitter.com/)
      application.matches?(env_for "http://anything.com").should be_false
      application.matches?(env_for "http://twitter.com").should be_true

      application.request_matchers << RequestMatcher.new(proc { request_method == "POST" })
      application.matches?(env_for "http://twitter.com").should be_false
      application.matches?(env_for "http://twitter.com", :method => :post).should be_true
    end

  end
end
