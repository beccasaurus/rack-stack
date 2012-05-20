require "spec_helper"
require "rack/test"

# Will break into smaller specs later ...
describe RackStack do
  include Rack::Test::Methods

  def app
    fail "You forgot to set an @app!" unless @app
    Rack::Lint.new @app
  end

  it "is a Rack application" do
    @app = RackStack.new do
      run lambda {|e| [200, {"Content-Type" => "text/plain"}, ["Hello World"]] }
    end

    get "/"

    last_response.body.should == "Hello World"
  end

  it "is a Rack middleware" do
    @app = Rack::Builder.new do
      use RackStack do
        run lambda {|e| [200, {"Content-Type" => "text/plain"}, ["Rack Stack"]] }
      end
      run lambda {|e| [200, {"Content-Type" => "text/plain"}, ["Rack Builder"]] }
    end

    get "/"

    last_response.body.should == "Rack Stack"
  end

  it "calls #default_app (or returns nil) if no application"

  it "calling #to_app requires a #run or #map statement" # test that it works OK with just #use (with short-circuiting middleware?)

  it "can #run application"
  it "can #run application :if => proc(Rack::Request)"
  it "can #run application :if => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #run application :if => { <Rack::Request attribute> => { <nested method call> => <value> } }"
  it "can #run application :unless => proc(Rack::Request)"
  it "can #run application :unless => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #run application :unless => { <Rack::Request attribute> => { <nested method call> => <value> } }"
  it "can add named application"
  it "can remove named application"

  it "can #use middleware"
  it "can #use middleware with arguments and block"
  it "can #use middleware :if => proc(Rack::Request)"
  it "can #use middleware :if => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can #use middleware :unless => proc(Rack::Request)"
  it "can #use middleware :unless => { <Rack::Request attribute> => <Rack::Request value> }"
  it "can add named middleware"
  it "can remove named middleware"
  it "can #use middleware even with :if/:unless/[etc] argument clashing edge cases"

end
