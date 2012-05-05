require "spec_helper"

describe Rack::ConditionalBuilder::Use do

  # Sample middleware class for our examples below.
  class FooMiddleware
    def initialize(app) @app = app end
    def call(env) @app.call(env) end
  end

  it "can #use a middleware" do
    builder = Rack::ConditionalBuilder.new do
      use FooMiddleware
    end

    builder.stack.length.should == 1
    builder.stack.first.should_have_attributes do
      name                 nil
      middleware_class     FooMiddleware
      middleware_arguments []
      middleware_block     nil
    end
  end

  it "can #use a middleware with arguments" do
    block_argument = lambda { }
    builder = Rack::ConditionalBuilder.new do
      use FooMiddleware, 1, :hello => "world", &block_argument
    end

    builder.stack.length.should == 1
    builder.stack.first.should_have_attributes do
      name                 nil
      middleware_class     FooMiddleware
      middleware_arguments [1, { :hello => "world" }]
      middleware_block     block_argument
    end
  end

  it "can #use a named middleware (and #get it)" do
    builder = Rack::ConditionalBuilder.new do
      use :foo, FooMiddleware
    end

    builder.stack.first.name.should == :foo
    builder.stack.first.should_have_attributes do
      name                 :foo
      middleware_class     FooMiddleware
      middleware_arguments []
      middleware_block     nil
    end

    # builder.get(:foo).should == 
  end

  it "can #use a named middleware with conditions (and #get it)"
  it "can #use a middleware :if => lambda {|request| request.attribute =~ /pattern/ }"
  it "can #use a middleware :if => { :requestAttribute => /pattern/ }"
  it "can #use a middleware :unless => lambda {|request| request.attribute == 'value' }"
  it "can #use a middleware :unless => { :requestAttribute => 'value' }"
  it "can #use a named middleware with arguments using a mix of :if/:unless and procs/==="
  it "can #use with a block argument"

  describe "#to_text" do
    it "renders middleware class name"
    it "renders middleware arguments, if any"
    it "renders :if/:unless conditionals with <proc>"
    it "renders :if/:unless conditionals with Hash of === attribute matchers"
  end

end
