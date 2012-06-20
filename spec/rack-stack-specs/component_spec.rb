require "spec_helper"

describe RackStack::Component do

  def env_for(*args)
    Rack::MockRequest.env_for(*args)
  end

  class ComponentClass
    include RackStack::Component
  end

  it "has a #name (optional)" do
    component = ComponentClass.new
    component.name.should be_nil
    component.name = :usually_a_symbol
    component.name.should == :usually_a_symbol
  end

  it "has many #request_matchers (which determine #matches?(env))" do
    component = ComponentClass.new
    component.request_matchers.should be_empty
    component.matches?(env_for "http://anything.com").should be_true

    component.add_request_matcher :host => /twitter.com/
    component.matches?(env_for "http://anything.com").should be_false
    component.matches?(env_for "http://twitter.com").should be_true

    component.add_request_matcher proc { request_method == "POST" }
    component.matches?(env_for "http://twitter.com").should be_false
    component.matches?(env_for "http://twitter.com", :method => :post).should be_true
  end

  it "is not a #use? #map? or #run?" do
    component = ComponentClass.new
    component.use?.should be_false
    component.map?.should be_false
    component.run?.should be_false
  end

end
