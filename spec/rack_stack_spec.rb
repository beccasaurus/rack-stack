require "spec_helper"

# TODO Clean up this spec (this was the first spec).  Will clean it up soon ...
describe RackStack do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  class ExampleMiddlewareClass
    def initialize(app) end
    def call(env) end
  end

  it "is a Rack application" do
    @app = RackStack.new do
      run simple_app { write "Hello World" }
    end

    get "/"

    last_response.body.should == "Hello World"
  end

  it "is a Rack middleware" do
    # Use Rack::Builder to build a simple Rack application, using RackStack as a middleware.
    @app = Rack::Builder.new {

      # Use RackStack here, just like you would use any other middleware
      use RackStack do

        # If /rack-stack is requested, this route will get hit.
        # Otherwise, RackStack will pass the #call through to the our application.
        map "/rack-stack" do
          run simple_app { write "Rack Stack!" }
        end
      end

      # If our middleware doesn't return a response, this is the default application 
      # that we'll fall back to.
      run simple_app { write "Rack::Builder outer app" }

    }.to_app

    get("/").body.should == "Rack::Builder outer app"

    get("/rack-stack").body.should == "Rack Stack!"
  end

  it "Rack::Builder only supports instance_eval-ing its block" do
    @ivar_app = simple_app { write "Hi from @ivar app" }

    @app = Rack::Builder.new {|o|
      o.run @ivar_app || simple_app { write "@ivar was out of scope" }
    }.to_app

    get("/").body.should == "@ivar was out of scope"
  end

  it "can pass a block argument to constructor (does not instance_eval)" do
    @ivar_app = simple_app { write "Hi from @ivar app" }

    @app = RackStack.new {|o|
      o.run @ivar_app || simple_app { write "@ivar was out of scope" }
    }.to_app

    get("/").body.should == "Hi from @ivar app"
  end

  it "calls #default_app (or raises exception) if no matching application found" do
    default_app = simple_app { write "Hello from Default App" }

    @app = RackStack.new(default_app) do
      map "/this-wont-match" do
        run simple_app { write "This won't match" }
      end
    end

    get("/").body.should == "Hello from Default App"
  end

  it "raises RackStack::NoMatchingApplicationError (with the RackStack and a stack trace)" do
    @app = RackStack.new do
      map "/this-wont-match" do
        run simple_app { write "This won't match" }
      end
    end
  
    begin
      get "/some-path"
    rescue Exception => ex
      exception = ex
    ensure
      exception.should be_an_instance_of RackStack::NoMatchingApplicationError
      exception.stack.should == @app.stack
      exception.env["PATH_INFO"].should == "/some-path"
    end
  end

  it "calling #to_app requires a #run or #map statement" do
    expect { RackStack.new { use ExampleMiddlewareClass }.to_app }.to raise_error(
      RuntimeError, "missing run or map statement"
    )

    RackStack.new { run simple_app }.to_app # OK
    RackStack.new { map "/foo" do end }.to_app # OK
  end

  it "can #run application" do
    @app = RackStack.new do
      run simple_app { write "Hi from application" }
    end
  end
  
end
