require "spec_helper"

describe RackStack, "#map" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
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
