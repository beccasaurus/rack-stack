require "spec_helper"

describe RackStack, "#use" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  before do
    @app         = RackStack.new
    @hello_app   = simple_app {|req,resp| resp.write "Hello from #{req.path_info}"   }
    @goodbye_app = simple_app {|req,resp| resp.write "Goodbye from #{req.path_info}" }
  end

  it "MiddlewareClass"
  it "MiddlewareClass, *arguments"
  it "MiddlewareClass, *arguments, &block"

  it "MiddlewareClass, :when => <RequestMatcher>"
  it "MiddlewareClass, *arguments, :when => <RequestMatcher>, &block"
  it "MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block"

  it ":middleware_name, MiddlewareClass"
  it ":middleware_name, MiddlewareClass, *arguments, :arg1 => true, :when => <RequestMatcher>, &block"

end
