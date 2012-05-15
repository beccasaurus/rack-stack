require "spec_helper"

# Rename ... builder-y?  builder router ... route builder (!)(?)
describe RouteBuilder do

  describe "Scenario: where you setup apps once" do
    it "first thoughts" do
      app = Rack::RouteBuilder.new do
        # Always
        use MiddlewareOne
        use MiddlewareTwo
        use MiddlewareThree, @foo, :arg1 => "val1"

        # Sometimes, eg. only before hitting part of fake twitter
        use MiddlewareThree, @foo, :arg1 => "val1", :if => { :host => "twitter.com" }
        use TwitterShim, :if => { :host => "twitter.com" }
        use TwitterShim, :if => lambda {|req| req.host == "twitter.com" }

        # Ok, what if I want to pass the middleware different initializer 
        # arguments based on something in the given request (which I can see if my :if).
        #
        # Like maybe we want a Rack::Static instance that serves a different :root 
        # based on the request.
        #
        # I hope nobody would need to do this so, if it doesn't work, i don't think 
        # we need to make this library flexible enough to handle that.
        #

        # Provide a name.  This lets you remove the middleware easily later.
        use :twitter_shim, TwitterShim
        
        # Running.  Due to the conditional nature of this, you can have multiple
        # run statements (with conditions).  You can only have 1 run statement 
        # without conditions (and you can't add any further statements after that).
        run FakeTwitter.new, :host => "twitter.com"
        run FakeTwitter.new, :if => lambda {|req| req.host == "twitter.com" }
        run :fake_twitter, FakeTwitter.new, :host => "twitter.com"

        run CatchAll.new
      end
    end
  end

  describe "Scenario: where you setup a router and add/remove apps in before/after blocks"

  describe "Scenario: where you setup a router and add/remove apps just for the duration" +
           " of calling a block" do

  end

end
