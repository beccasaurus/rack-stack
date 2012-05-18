require "rack_apps"
require "rspec"
require "rack/test"

describe RackApps do
  describe "MVP" do
    include Rack::Test::Methods

    def rack_apps
      @rack_apps ||= RackApps.new
    end

    alias app rack_apps # for rack-test

    it "can add apps with different conditions and requests are routed properly" do
      rack_apps.add :first, :path_info => %r{^/first}, :app => lambda {|env|
        response = Rack::Response.new
        response.write "Hello from first"
        response.finish
      }

      rack_apps.add :second, :path_info => %r{^/second}, :app => lambda {|env|
        response = Rack::Response.new
        response.write "Hello from second"
        response.finish
      }

      get "/first/anything"
      last_response.body.should == "Hello from first"

      get "/second/anything"
      last_response.body.should == "Hello from second"

      expect { get "/does-not-match-anything" }.to raise_error(RuntimeError, /No matching app found/)
    end
  end
end
