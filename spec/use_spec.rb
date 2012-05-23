require "spec_helper"

describe RackStack, "#use" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  # Wraps the response text in provided text (default: "*")
  class MiddlewareToUse
    def initialize(app, character = "*", options = nil)
      @app = app
      @character = character
      @options = options || {}
      @options[:times] ||= 1
    end

    def text
      @character * @options[:times]
    end

    def call(env)
      status, headers, body_parts = @app.call(env)
      body = ""
      body_parts.each {|part| body << part }
      body = "#{text}#{body}#{text}"
      headers["Content-Length"] = body.length.to_s
      [status, headers, body]
    end
  end

  before do
    @app         = RackStack.new
    @hello_app   = simple_app {|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = simple_app {|req,resp| resp.write "Goodbye from #{req.path_info}" }
  end

  it "MiddlewareClass" do
    @app.use MiddlewareToUse

    @app.trace.should == clean_trace("use MiddlewareToUse")

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"
  end

  it "MiddlewareClass, *arguments" do
    @app.use MiddlewareToUse, "%"

    @app.trace.should == clean_trace('use MiddlewareToUse, "%"')

    @app.run @hello_app
    get("/").body.should == "%Hello from /%"
  end

  it "MiddlewareClass, *arguments, &block" do
    @app.use MiddlewareToUse, "%" do end

    @app.trace.start_with?('use MiddlewareToUse, "%", &#<Proc:').should be_true

    @app.run @hello_app
    get("/").body.should == "%Hello from /%"
  end

  it "MiddlewareClass, :when => <RequestMatcher>" do
    @app.use MiddlewareToUse, :when => { :path_info => "/" }

    @app.trace.should == clean_trace('use MiddlewareToUse, when: [{:path_info=>"/"}]')

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

  it "MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block" do
    @app.use MiddlewareToUse, "%", :times => 3, :when => { :path_info => "/" } do end

    @app.trace.start_with?('use MiddlewareToUse, "%", {:times=>3}, &#<Proc:').should be_true
    @app.trace.end_with?(", when: [{:path_info=>\"/\"}]\n").should be_true

    @app.run @hello_app
    get("/").body.should == "%%%Hello from /%%%"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

  it ":middleware_name, MiddlewareClass" do
    @app.use :response_wrapper, MiddlewareToUse

    @app.trace.should == clean_trace("use :response_wrapper, MiddlewareToUse")

    @app.run @hello_app
    get("/").body.should == "*Hello from /*"

    @app.remove :response_wrapper
    get("/").body.should == "Hello from /"
  end

  it "same middleware may be added many times with same/different names" do
    @app.use :response_wrapper, MiddlewareToUse, "A"
    @app.use :response_wrapper, MiddlewareToUse, "B"
    @app.use :different_name, MiddlewareToUse, "C"

    @app.trace.should == clean_trace(%{
      use :response_wrapper, MiddlewareToUse, "A"
      use :response_wrapper, MiddlewareToUse, "B"
      use :different_name, MiddlewareToUse, "C"
    })

    @app.run @hello_app
    get("/").body.should == "ABCHello from /CBA"

    @app.remove :response_wrapper
    get("/").body.should == "CHello from /C" # removed *both* with this name

    @app.remove :different_name
    get("/").body.should == "Hello from /" # removed last one (different name)
  end

  it ":middleware_name, MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block" do
    @app.use :response_wrapper, MiddlewareToUse, "%", :times => 3, :when => { :path_info => "/" } do end

    @app.trace.start_with?('use :response_wrapper, MiddlewareToUse, "%", {:times=>3}, &#<Proc:').should be_true
    @app.trace.end_with?(", when: [{:path_info=>\"/\"}]\n").should be_true

    @app.run @hello_app
    get("/").body.should == "%%%Hello from /%%%"
    get("/foo").body.should == "Hello from /foo" # :when didn't hit this time, so no middleware
  end

end
