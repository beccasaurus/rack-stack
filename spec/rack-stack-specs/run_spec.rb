require "spec_helper"

describe RackStack, "#run" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app         = RackStack.new
    @hello_app   = SimpleApp.new(:hello){|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = SimpleApp.new(:goodbye){|req,resp| resp.write "Goodbye from #{req.path_info}" }
  end

  it "@app" do
    @app.run @hello_app

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run SimpleApp<hello>
      end
    })

    get("/foo/bar").body.should == "Hello from /foo/bar"
  end

  it "@app, :when => <RequestMatcher>" do
    @app.run @hello_app,   :when => { :path_info => /hello/   }
    @app.run @goodbye_app, :when => { :path_info => /goodbye/ }

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run SimpleApp<hello>, when: [{:path_info=>/hello/}]
        run SimpleApp<goodbye>, when: [{:path_info=>/goodbye/}]
      end
    })

    get("/hello/foo").body.should == "Hello from /hello/foo"
    get("/goodbye/foo").body.should == "Goodbye from /goodbye/foo"
  end

  it ":app_name, @app" do
    @app.run :app_name, @hello_app

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run :app_name, SimpleApp<hello>
      end
    })

    get("/").body.should == "Hello from /"

    @app.remove :app_name
    @app.stack.length.should == 0
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
  end

  it ":app_name, @app, :when => <RequestMatcher>" do
    @app.run :app_name, @hello_app, :when => { :path_info => /.*/ }

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run :app_name, SimpleApp<hello>, when: [{:path_info=>/.*/}]
      end
    })

    get("/").body.should == "Hello from /"

    @app.remove :app_name
    @app.stack.length.should == 0
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
  end

end
