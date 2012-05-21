require "spec_helper"

describe RackStack, "#run" do
  include Rack::Test::Methods

  def app
    fail "You forgot to set an @app!" unless @app
    Rack::Lint.new @app
  end

  it "run @app" do
    @app = RackStack.new do
      run simple_app {|req,resp| resp.write "Welcome to #{req.path_info}" }
    end

    get("/foo/bar").body.should == "Welcome to /foo/bar"
  end

  it "run @app, :when => <RequestMatcher>"

  it "run :foo, @app"

  it "run :foo, @app, :when => <RequestMatcher>"

end
