require "spec_helper"

describe RackStack, "#map" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  it "first #map to match path 'wins'" do
    @app = RackStack.new do
      map("/"){ run simple_app(:first){ write "first" } }
      map("/"){ run simple_app(:second){ write "second" } }
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
      run simple_app(:default){ write "default" }

      map "/foo" do
        use ResponseWrapperMiddleware, "[foo]"
        run simple_app(:foo){ write "foo" }

        # TODO add inner-map
      end
    end

    @app.trace.should == clean_trace(%{
      use ResponseWrapperMiddleware
      map "/foo" do
        use ResponseWrapperMiddleware, "[foo]"
        run SimpleApp<foo>
      end
      run SimpleApp<default>
    })

    get("/").body.should == "*default*"
    get("/foo").body.should == "*[foo]foo[foo]*"
  end

  it "can have a name" do
    @app = RackStack.new do
      map :first, "/foo" do
        run simple_app(:first){ write "first" }
      end
      map :second, "/foo" do
        run simple_app(:second){ write "second" }
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
