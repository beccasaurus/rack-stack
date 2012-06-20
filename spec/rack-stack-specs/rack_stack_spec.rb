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
    @app.run SimpleApp.new { write "Hello World" }

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
          run SimpleApp.new { write "Rack Stack!" }
        end
      end

      # If our middleware doesn't return a response, this is the default application 
      # that we'll fall back to.
      run SimpleApp.new { write "Rack::Builder outer app" }

    }.to_app

    get("/").body.should == "Rack::Builder outer app"

    get("/rack-stack").body.should == "Rack Stack!"
  end

  it "Rack::Builder only supports instance_eval-ing its block" do
    @ivar_app = SimpleApp.new { write "Hi from @ivar app" }

    @app = Rack::Builder.new {|o|
      o.run @ivar_app || SimpleApp.new { write "@ivar was out of scope" }
    }.to_app

    get("/").body.should == "@ivar was out of scope"
  end

  it "does not instance_eval block passed with block argument" do
    @ivar_app = SimpleApp.new { write "Hi from @ivar app" }

    @app = RackStack.new {|o|
      o.run @ivar_app || SimpleApp.new { write "@ivar was out of scope" }
    }.to_app

    get("/").body.should == "Hi from @ivar app"
  end

  it "calls #default_app (or raises exception) if no matching application found" do
    default_app = SimpleApp.new { write "Hello from Default App" }

    @app = RackStack.new(default_app) do
      map "/this-wont-match" do
        run SimpleApp.new { write "This won't match" }
      end
    end

    get("/").body.should == "Hello from Default App"

    @app.default_app = SimpleApp.new { write "Changed default app!" }

    get("/").body.should == "Changed default app!"
  end

  it "raises RackStack::NoMatchingApplicationError (with the RackStack)" do
    begin
      get "/some-path"
    rescue Exception => ex
      exception = ex
    ensure
      exception.should be_an_instance_of RackStack::NoMatchingApplicationError
      exception.rack_stack.should == @app
      exception.env["PATH_INFO"].should == "/some-path"
    end
  end

  it "calling #to_app requires a #run or #map statement" do
    expect { RackStack.new { use ExampleMiddlewareClass }.to_app }.to raise_error(
      RuntimeError, "missing run or map statement"
    )

    RackStack.new { run SimpleApp.new }.to_app # OK
    RackStack.new { map "/foo" do end }.to_app # OK
  end

  it "can #run application" do
    @app.run SimpleApp.new { write "Hi from application" }

    get("/").body.should == "Hi from application"
  end
  
  it "RackStack#remove removes components from nested maps" do
    @app = RackStack.new do
      map "/foo" do
        map "/foo" do
          run :name, SimpleApp.new(:inner_inner)
        end
        run :name, SimpleApp.new(:inner)
      end
      run :name, SimpleApp.new(:outer)
    end

    @app.trace.should == clean_trace(%{
      RackStack.new do
        map "/foo" do
          map "/foo" do
            run :name, SimpleApp<inner_inner>
          end
          run :name, SimpleApp<inner>
        end
        run :name, SimpleApp<outer>
      end
    })

    @app.remove(:name)

    @app.trace.should == clean_trace(%{
      RackStack.new do
        map "/foo" do
          map "/foo" do
          
          end
        end
      end
    })
  end

  it "can #get(:name) Endpoint (returns Rack endpoint instance)" do
    @app.run :outer, SimpleApp.new(:outer)
    @app.map :foo_map, "/foo" do
      run :inner_foo, SimpleApp.new(:inner_foo)
      map :bar_map, "/bar" do
        run :inner_bar, SimpleApp.new(:inner_bar)
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

  it "can #get(:name){|app| app.app_method }" do
    @app.use :outer, NamedMiddleware, :outer

    value = nil
    @app.get(:outer){|app| value = app.name }
    value.should == :outer

    value = nil
    @app.outer {|app| value = app.name }
    value.should == :outer
  end

  it "can #get(:name){ app_method }" do
    @app.use :outer, NamedMiddleware, :outer

    value = nil
    @app.get(:outer){ value = name }
    value.should == :outer

    value = nil
    @app.outer { value = name }
    value.should == :outer
  end

  it "can have :when conditions (default_app is called if conditions not matched)" do
    @app = RackStack.new :when => { :host => "foo.com" } do
      run SimpleApp.new(:foo){ write "hi from foo.com app" }
    end

    @app.trace.should == clean_trace(%{
      RackStack.new when: [{:host=>"foo.com"}] do
        run SimpleApp<foo>
      end
    })

    # When conditions aren't met, NoMatchingApplicationError is raised
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
    @app.default_app = SimpleApp.new { write "Hi from default app" }
    get("/").body.should == "Hi from default app"

    # Oh, and if there's a #map, ofcourse, it returns a 404 instead though.
    @app.map("/bar-map"){ run SimpleApp.new { write "Hi from /bar-map" }}
    get("/").body.should == "Hi from default app"
    @app.default_app = nil
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)

    RackStack.rack_builder_compatibility = true
    get("/").body.should == "Not Found: /"
  end
end
