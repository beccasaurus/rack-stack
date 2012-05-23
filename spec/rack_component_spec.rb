require "spec_helper"

class RackStack
  describe RackComponent do

    def env_for(*args)
      Rack::MockRequest.env_for(*args)
    end

    it "has a #name (optional)" do
      component = RackComponent.new
      component.name.should be_nil
      component.name = :usually_a_symbol
      component.name.should == :usually_a_symbol
    end

    it "has many #request_matchers (which determine #matches?(env))" do
      component = RackComponent.new
      component.request_matchers.should be_empty
      component.matches?(env_for "http://anything.com").should be_true

      component.request_matchers << RequestMatcher.new(:host => /twitter.com/)
      component.matches?(env_for "http://anything.com").should be_false
      component.matches?(env_for "http://twitter.com").should be_true

      component.request_matchers << RequestMatcher.new(proc { request_method == "POST" })
      component.matches?(env_for "http://twitter.com").should be_false
      component.matches?(env_for "http://twitter.com", :method => :post).should be_true
    end

  end
end
