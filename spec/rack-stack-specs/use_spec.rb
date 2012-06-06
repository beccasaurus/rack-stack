require "spec_helper"

describe RackStack, "#use" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  class MiddlewareThatTracksAllInstances < NamedMiddleware
    def self.instances
      @instances ||= []
    end

    def initialize(*args)
      self.class.instances.push self
      super
    end
  end

  before do
    @app         = RackStack.new
    @hello_app   = SimpleApp.new {|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = SimpleApp.new {|req,resp| resp.write "Goodbye from #{req.path_info}" }
    MiddlewareThatTracksAllInstances.instances.clear
  end

  it "MiddlewareClass" do
    @app.use ResponseWrapperMiddleware

    @app.trace.should == clean_trace("use ResponseWrapperMiddleware")

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"
  end

  it "MiddlewareClass, *arguments" do
    @app.use ResponseWrapperMiddleware, "%"

    @app.trace.should == clean_trace('use ResponseWrapperMiddleware, "%"')

    @app.run @hello_app
    get("/").body.should == "%Hello from /%"
  end

  it "MiddlewareClass, *arguments, &block" do
    @app.use ResponseWrapperMiddleware, "%" do end

    @app.trace.start_with?('use ResponseWrapperMiddleware, "%", &#<Proc:').should be_true

    @app.run @hello_app
    get("/").body.should == "%Hello from /%"
  end

  it "MiddlewareClass, :when => <RequestMatcher>" do
    @app.use ResponseWrapperMiddleware, :when => { :path_info => "/" }

    @app.trace.should == clean_trace('use ResponseWrapperMiddleware, when: [{:path_info=>"/"}]')

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

  it "MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block" do
    @app.use ResponseWrapperMiddleware, "%", :times => 3, :when => { :path_info => "/" } do end

    @app.trace.start_with?('use ResponseWrapperMiddleware, "%", {:times=>3}, &#<Proc:').should be_true
    @app.trace.end_with?(", when: [{:path_info=>\"/\"}]\n").should be_true

    @app.run @hello_app
    get("/").body.should == "%%%Hello from /%%%"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

  it ":middleware_name, MiddlewareClass" do
    @app.use :response_wrapper, ResponseWrapperMiddleware

    @app.trace.should == clean_trace("use :response_wrapper, ResponseWrapperMiddleware")

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"

    @app.remove :response_wrapper
    get("/").body.should == "Hello from /"
  end

  it "same middleware may be added many times with same/different names" do
    @app.use :response_wrapper, ResponseWrapperMiddleware, "A"
    @app.use :response_wrapper, ResponseWrapperMiddleware, "B"
    @app.use :different_name, ResponseWrapperMiddleware, "C"

    @app.trace.should == clean_trace(%{
      use :response_wrapper, ResponseWrapperMiddleware, "A"
      use :response_wrapper, ResponseWrapperMiddleware, "B"
      use :different_name, ResponseWrapperMiddleware, "C"
    })

    @app.run @hello_app
    get("/").body.should == "ABCHello from /CBA"

    @app.remove :response_wrapper
    get("/").body.should == "CHello from /C" # removed *both* with this name

    @app.remove :different_name
    get("/").body.should == "Hello from /" # removed last one (different name)
  end

  it ":middleware_name, MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block" do
    @app.use :response_wrapper, ResponseWrapperMiddleware, "%", :times => 3, :when => { :path_info => "/" } do end

    @app.trace.start_with?('use :response_wrapper, ResponseWrapperMiddleware, "%", {:times=>3}, &#<Proc:').should be_true
    @app.trace.end_with?(", when: [{:path_info=>\"/\"}]\n").should be_true

    @app.run @hello_app
    get("/").body.should == "%%%Hello from /%%%"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

  it "MiddlewareThatTracksAllInstances sample class works as expected" do
    MiddlewareThatTracksAllInstances.instances.should be_empty

    MiddlewareThatTracksAllInstances.new SimpleApp.new, "First"
    MiddlewareThatTracksAllInstances.instances.length.should == 1
    MiddlewareThatTracksAllInstances.instances.last.to_s.should == "MiddlewareThatTracksAllInstances<First>"

    MiddlewareThatTracksAllInstances.new SimpleApp.new, "Second"
    MiddlewareThatTracksAllInstances.instances.length.should == 2
    MiddlewareThatTracksAllInstances.instances.last.to_s.should == "MiddlewareThatTracksAllInstances<Second>"
  end

  it "reuses the same middleware instance for all requests (so it may have state)" do
    MiddlewareThatTracksAllInstances.instances.should be_empty

    @app.use MiddlewareThatTracksAllInstances, "MyMiddleware"
    @app.run SimpleApp.new

    get "/"
    MiddlewareThatTracksAllInstances.instances.length.should == 1
    MiddlewareThatTracksAllInstances.instances.first.to_s.should == "MiddlewareThatTracksAllInstances<MyMiddleware>"

    get "/"
    get "/"
    get "/"
    MiddlewareThatTracksAllInstances.instances.length.should == 1 # no additional instances instantiated
  end

end
