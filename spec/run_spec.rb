require "spec_helper"

describe RackStack, "#run" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  def clean_trace(trace)
    trace.gsub(/^ {6}/, "").strip + "\n"
  end

  before do
    @app         = RackStack.new
    @hello_app   = simple_app(:hello){|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = simple_app(:goodbye){|req,resp| resp.write "Goodbye from #{req.path_info}" }
  end

  it "@app" do
    @app.run @hello_app

    get("/foo/bar").body.should == "Hello from /foo/bar"

    @app.stack.length.should == 1
    @app.stack[0].should be_an_instance_of RackStack::RackApplication
    @app.stack[0].application.should == @hello_app
    @app.stack[0].request_matchers.should be_empty
  end

  it "@app, :when => <RequestMatcher>" do
    @app.run @hello_app,   :when => { :path_info => /hello/   }
    @app.run @goodbye_app, :when => { :path_info => /goodbye/ }

    get("/hello/foo").body.should == "Hello from /hello/foo"
    get("/goodbye/foo").body.should == "Goodbye from /goodbye/foo"

    pending "This fails.  Need to write specs for StackTracer."

    @app.trace.should == clean_trace(%[
      run SimpleApp<hello>, :when => { :path => /hello/ }
      run SimpleApp<goodbye>, :when => { :path => /goodbye/ }
    ])
  end

  # These are the assertions that I had to double-check the unit-level sanity 
  # of everything (after asserting that the acceptance level test passed).
  #
  # Experimenting with replacing these with testing against the stacktrace, which 
  # is more visual and potentially easier to understand/maintain (even though it 
  # may be somewhat annoying to work with a big string).
  #
  # @app.stack.length.should == 2
  # @app.stack[0].should be_an_instance_of RackStack::RackApplication
  # @app.stack[0].application.should == @hello_app
  # @app.stack[0].request_matchers.length.should == 1
  # @app.stack[0].request_matchers.first.matcher.should == hello_matcher
  # @app.stack[1].should be_an_instance_of RackStack::RackApplication
  # @app.stack[1].application.should == @goodbye_app
  # @app.stack[1].request_matchers.length.should == 1
  # @app.stack[1].request_matchers.first.matcher.should == goodbye_matcher

  it ":app_name, @app" do
    @app.run :app_name, @hello_app

    get("/").body.should == "Hello from /"

    @app.stack.length.should == 1
    @app.stack.first.name.should == :app_name
    @app.stack.first.should be_an_instance_of RackStack::RackApplication
    @app.stack.first.application.should == @hello_app
    @app[:app_name].should == @hello_app
    @app.app_name.should == @hello_app
    @app.respond_to?(:app_name).should be_true

    @app.remove :app_name
    @app.stack.length.should == 0
    expect { get("/") }.to raise_error(RackStack::NoMatchingApplicationError)
  end

  it ":app_name, @app, :when => <RequestMatcher>"

end
