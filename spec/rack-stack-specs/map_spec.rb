require "spec_helper"

describe RackStack, "#map" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app = RackStack.new
    @app.stack.should be_empty
  end

  # For Rack::Builder compatibility.
  it "if RackStack includes at least 1 #map (URLMap), returns 404/Not Found (instead of raising NoMatchingApplicationError)" do
    @app.map "/foo" do
      run SimpleApp.new { write "hi from /foo" }
    end

    get("/foo").body.should == "hi from /foo"

    get "/wrong-path"
    last_response.body.should == "Not Found: /wrong-path"
    last_response.status.should == 404
    last_response.content_type.should == "text/plain"
    last_response["X-Cascade"].should == "pass"

    # Note: if there's a default_app, the RackStack falls back to that.
    @app.default_app = SimpleApp.new { write "hi from default_app" }
    get("/wrong-path").body.should == "hi from default_app"
  end

  it "'/path'" do
    @app.map "/path" do
      run SimpleApp.new(:the_app){ write "Hello from the app" }
    end

    @app.trace.should == clean_trace(%{
      map "/path" do
        run SimpleApp<the_app>
      end
    })

    get("/path").body.should == "Hello from the app"
  end

  it "'/path', :when => <RequestMatcher>" do
    @app.map "/path", :when => { :host => "foo.com" } do
      run SimpleApp.new(:foo_app){ write "Hello from foo.com/path" }
    end
    @app.map "/path", :when => { :host => "bar.com" } do
      run SimpleApp.new(:bar_app){ write "Hello from bar.com/path" }
    end

    @app.trace.should == clean_trace(%{
      map "/path", when: [{:host=>"foo.com"}] do
        run SimpleApp<foo_app>
      end
      map "/path", when: [{:host=>"bar.com"}] do
        run SimpleApp<bar_app>
      end
    })

    get("http://foo.com/path").body.should == "Hello from foo.com/path"
    get("http://bar.com/path").body.should == "Hello from bar.com/path"
    get("http://DIFF.com/path").body.should == "Not Found: /path"
  end

  it "first #map to match path 'wins'" do
    @app = RackStack.new do
      map("/"){ run SimpleApp.new(:first){ write "first" } }
      map("/"){ run SimpleApp.new(:second){ write "second" } }
    end

    @app.trace.should == clean_trace(%{
      map "/" do
        run SimpleApp<first>
      end
      map "/" do
        run SimpleApp<second>
      end
    })

    get("/").body.should == "first"
  end

  it "using #use, #run, and #map" do
    @app = RackStack.new do
      use ResponseWrapperMiddleware
      run SimpleApp.new(:default){ write "default" }

      map "/foo" do
        # The statements in here are intentionally out of order. We should 
        # see #use, then #map, then #run because that's the correct order of the stack.
        run SimpleApp.new(:foo){ write "foo" }
        use ResponseWrapperMiddleware, "[foo]"
        map "/inner" do
          run SimpleApp.new(:inner){ write "inner" }
          use ResponseWrapperMiddleware, "[inner]"
        end
      end
    end

    @app.trace.should == clean_trace(%{
      use ResponseWrapperMiddleware
      map "/foo" do
        use ResponseWrapperMiddleware, "[foo]"
        map "/inner" do
          use ResponseWrapperMiddleware, "[inner]"
          run SimpleApp<inner>
        end
        run SimpleApp<foo>
      end
      run SimpleApp<default>
    })

    get("/").body.should == "*default*"
    get("/foo").body.should == "*[foo]foo[foo]*"
    get("/foo/inner").body.should == "*[foo][inner]inner[inner][foo]*"
  end

  it "can have a name" do
    @app = RackStack.new do
      map :first, "/foo" do
        run SimpleApp.new(:first){ write "first" }
      end
      map :second, "/foo" do
        run SimpleApp.new(:second){ write "second" }
      end
    end

    @app.trace.should == clean_trace(%{
      map :first, "/foo" do
        run SimpleApp<first>
      end
      map :second, "/foo" do
        run SimpleApp<second>
      end
    })

    get("/foo").body.should == "first"

    @app.remove :first
    get("/foo").body.should == "second"
  end
end
