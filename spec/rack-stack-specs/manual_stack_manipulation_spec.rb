require "spec_helper"

describe "Manual stack manipulation" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app = RackStack.new do
      run SimpleApp.new(:default){ write "default" }
    end

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run SimpleApp<default>
      end
    })

    get("/").body.should == "default"
  end

  describe "adding applications to run" do
    it "first" do
      @app.stack.push RackStack::Run.new SimpleApp.new(:last){ write "run me last" }

      @app.trace.should == clean_trace(%{
        RackStack.new do
          run SimpleApp<default>
          run SimpleApp<last>
        end
      }, :indent => 8)

      get("/").body.should == "default"
    end

    it "last" do
      @app.stack.unshift RackStack::Run.new SimpleApp.new(:first){ write "run me first!" }
      @app.trace.should == clean_trace(%{
        RackStack.new do
          run SimpleApp<first>
          run SimpleApp<default>
        end
      }, :indent => 8)
      get("/").body.should == "run me first!"
    end
  end

  it "can add/remove middleware to ::use"
  it "can add/remove nested app to ::map"

end
