require "spec_helper"

describe RackStack, "#run" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app         = RackStack.new
    @hello_app   = simple_app(:hello){|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = simple_app(:goodbye){|req,resp| resp.write "Goodbye from #{req.path_info}" }
  end

  it "@app" do
    @app.run @hello_app

    @app.trace.should == clean_trace("run SimpleApp<hello>")

    get("/foo/bar").body.should == "Hello from /foo/bar"
  end

  it "@app, :when => <RequestMatcher>" do
    @app.run @hello_app,   :when => { :path_info => /hello/   }
    @app.run @goodbye_app, :when => { :path_info => /goodbye/ }

    @app.trace.should == clean_trace(%{
      run SimpleApp<hello>, when: [{:path_info=>/hello/}]
      run SimpleApp<goodbye>, when: [{:path_info=>/goodbye/}]
    })

    get("/hello/foo").body.should == "Hello from /hello/foo"
    get("/goodbye/foo").body.should == "Goodbye from /goodbye/foo"
  end

  it ":app_name, @app" do
    @app.run :app_name, @hello_app

    @app.trace.should == "run :app_name, SimpleApp<hello>\n"

    get("/").body.should == "Hello from /"

    @app.remove :app_name
    @app.stack.length.should == 0
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
  end

  it ":app_name, @app, :when => <RequestMatcher>" do
    @app.run :app_name, @hello_app, :when => { :path_info => /.*/ }

    @app.trace.should == "run :app_name, SimpleApp<hello>, when: [{:path_info=>/.*/}]\n"

    get("/").body.should == "Hello from /"

    @app.remove :app_name
    @app.stack.length.should == 0
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
  end

end
