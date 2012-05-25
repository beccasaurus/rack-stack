require "spec_helper"

describe "Manual stack manipulation" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app = RackStack.new do
      run simple_app(:default){ write "default" }
    end
    @app.trace.should == clean_trace("run SimpleApp<default>")
    get("/").body.should == "default"
  end

  describe "adding applications to run" do
    it "first" do
      @app.stack.push RackStack.run simple_app(:last){ write "run me last" }
      @app.trace.should == clean_trace(%{
        run SimpleApp<default>
        run SimpleApp<last>
      }, :indent => 8)
      get("/").body.should == "default"
    end

    it "last" do
      @app.stack.unshift RackStack.run simple_app(:first){ write "run me first!" }
      @app.trace.should == clean_trace(%{
        run SimpleApp<first>
        run SimpleApp<default>
      }, :indent => 8)
      get("/").body.should == "run me first!"
    end
  end

  it "can add/remove middleware to ::use"
  it "can add/remove nested app to ::map"

end
