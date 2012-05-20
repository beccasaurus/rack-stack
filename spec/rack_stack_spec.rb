require "spec_helper"
require "rack/test"

# Helper for building little Rack applications.
#
#   simple_app { write "Hello" }
#   simple_app {|response| response.write "Hello" }
#   simple_app {|request, response| response.write "You requested #{request['PATH_INFO']}" }
#
def simple_app(&block)
  lambda {|env|
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    if block.arity <= 0
      response.instance_eval(&block)
    elsif block.arity == 1
      block.call(response)
    else
      block.call(request, response)
    end
    response.finish
  }
end

# Will break into smaller specs later ...
describe RackStack do
  include Rack::Test::Methods

  def app
    fail "You forgot to set an @app!" unless @app
    Rack::Lint.new @app
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

  it "calling #to_app requires a #run or #map statement" # test that it works OK with just #use (with short-circuiting middleware?)

  it "can #run application" do
    @app = RackStack.new do
      run simple_app { write "Hi from application" }
    end
  end
  
  # NOTE TODO Once this passes, I think it would be OK to start busting out some unit tests
  it "can #run application :if => lambda { true }" do
    @app = RackStack.new do
      run simple_app { write "Hi from FOO" }, :if => lambda { path_info =~ /foo/ }
      run simple_app { write "Hi from BAR" }, :if => lambda { path_info =~ /bar/ }
      run simple_app { write "Catch all" }
    end

    get("/").body.should == "Catch all"
    get("/foo").body.should == "Hi from FOO"
    get("/bar").body.should == "Hi from BAR"
  end

  it "can #run application :if => lambda {|request| true }" do
    @app = RackStack.new do
      run simple_app { write "Hi from FOO" }, :if => lambda {|request| request.path_info =~ /foo/ }
      run simple_app { write "Hi from BAR" }, :if => lambda {|request| request.path_info =~ /bar/ }
      run simple_app { write "Catch all" }
    end

    get("/").body.should == "Catch all"
    get("/foo").body.should == "Hi from FOO"
    get("/bar").body.should == "Hi from BAR"
  end

  it "can #run application :if => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #run application :if => { <Rack::Request attribute> => { <nested method call> => <value> } }"

  it "can #run application :unless => lambda { true }" do
    @app = RackStack.new do
      run simple_app { write "Not BAR!" }, :unless => lambda { path_info == "/" || path_info =~ /bar/ }
      run simple_app { write "Not FOO!" }, :unless => lambda { path_info == "/" || path_info =~ /foo/ }
      run simple_app { write "Catch all" }
    end

    get("/").body.should == "Catch all"
    get("/foo").body.should == "Not BAR!"
    get("/bar").body.should == "Not FOO!"
  end

  it "can #run application :unless => lambda {|request| true }"

  it "can #run application :unless => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #run application :unless => { <Rack::Request attribute> => { <nested method call> => <value> } }"
  it "can add named application"
  it "can remove named application"

  it "can #use middleware"
  it "can #use middleware with arguments and block"
  it "can #use middleware :if => proc(Rack::Request)"
  it "can #use middleware :if => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #use middleware :unless => proc(Rack::Request)"
  it "can #use middleware :unless => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can add named middleware"
  it "can remove named middleware"
  it "can #use middleware even with :if/:unless/[etc] argument clashing edge cases"

end
