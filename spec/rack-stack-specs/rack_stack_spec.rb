require "spec_helper"

describe RackStack do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  class ExampleMiddlewareClass
    def initialize(app) end
    def call(env) end
  end

  before do
    @app = RackStack.new
  end

  it "is a Rack application" do
    @app.run simple_app { write "Hello World" }

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
    @app.run simple_app, :when => { :path_info => /this won't match any paths we request/ }
  
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
    @app.run simple_app { write "Hi from application" }

    get("/").body.should == "Hi from application"
  end
  
  it "RackStack#remove removes components from nested maps" do
    @app = RackStack.new do
      map "/foo" do
        map "/foo" do
          run :name, simple_app(:inner_inner)
        end
        run :name, simple_app(:inner)
      end
      run :name, simple_app(:outer)
    end

    @app.trace.should == clean_trace(%{
      map "/foo" do
        map "/foo" do
          run :name, SimpleApp<inner_inner>
        end
        run :name, SimpleApp<inner>
      end
      run :name, SimpleApp<outer>
    })

    @app.remove(:name)

    @app.trace.should == clean_trace(%{
      map "/foo" do
        map "/foo" do
          end
      end
    })
  end

  it "can #get(:name) Endpoint (returns Rack endpoint instance)" do
    @app.run :outer, simple_app(:outer)
    @app.map :foo_map, "/foo" do
      run :inner_foo, simple_app(:inner_foo)
      map :bar_map, "/bar" do
        run :inner_bar, simple_app(:inner_bar)
      end
    end

    @app.get(:outer).to_s.should == "SimpleApp<outer>"
    @app.get(:foo_map).should be_a(RackStack)
    @app.get(:foo_map).get(:inner_foo).to_s.should == "SimpleApp<inner_foo>"
    @app.get(:foo_map).get(:bar_map).get(:inner_bar).to_s.should == "SimpleApp<inner_bar>"

    # []
    @app[:outer].to_s.should == "SimpleApp<outer>"
    @app[:foo_map].should be_a(RackStack)
    @app[:foo_map][:inner_foo].to_s.should == "SimpleApp<inner_foo>"
    @app[:foo_map][:bar_map][:inner_bar].to_s.should == "SimpleApp<inner_bar>"

    # method_missing
    @app.outer.to_s.should == "SimpleApp<outer>"
    @app.foo_map.should be_a(RackStack)
    @app.foo_map.inner_foo.to_s.should == "SimpleApp<inner_foo>"
    @app.foo_map.bar_map.inner_bar.to_s.should == "SimpleApp<inner_bar>"
  end

  # @app.use :foo, NamedMiddleware, "foo"
  it "can #get(:name) Middleware (returns Rack middleware instance)" do
    @app.use :outer, NamedMiddleware, :outer
    @app.map :foo_map, "/foo" do
      use :inner_foo, NamedMiddleware, :inner_foo
      map :bar_map, "/bar" do
        use :inner_bar, NamedMiddleware, :inner_bar
      end
    end

    @app.get(:outer).to_s.should == "NamedMiddleware<outer>"
    @app.get(:foo_map).should be_a(RackStack)
    @app.get(:foo_map).get(:inner_foo).to_s.should == "NamedMiddleware<inner_foo>"
    @app.get(:foo_map).get(:bar_map).get(:inner_bar).to_s.should == "NamedMiddleware<inner_bar>"

    # []
    @app[:outer].to_s.should == "NamedMiddleware<outer>"
    @app[:foo_map].should be_a(RackStack)
    @app[:foo_map][:inner_foo].to_s.should == "NamedMiddleware<inner_foo>"
    @app[:foo_map][:bar_map][:inner_bar].to_s.should == "NamedMiddleware<inner_bar>"

    # method_missing
    @app.outer.to_s.should == "NamedMiddleware<outer>"
    @app.foo_map.should be_a(RackStack)
    @app.foo_map.inner_foo.to_s.should == "NamedMiddleware<inner_foo>"
    @app.foo_map.bar_map.inner_bar.to_s.should == "NamedMiddleware<inner_bar>"
  end
end
