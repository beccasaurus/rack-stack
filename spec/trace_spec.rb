require "spec_helper"

describe RackStack, "#trace" do

  class ExampleMiddlewareClass
    def initialize(app)
      @app = app
    end
    def call(env)
      @app.call(env)
    end
  end

  before do
    @app = RackStack.new
    @example_app = simple_app(:example_app)
  end

  it "no components" do
    @app.trace.should == ""
  end

  it "run @app" do
    @app.run @example_app
    @app.trace.should == "run SimpleApp<example_app>\n"
  end

  it "run @app, when: <RequestMatcher>" do
    @app.run @example_app, :when => { :host => /twitter.com/ }
    @app.trace.should == "run SimpleApp<example_app>, when: [{:host=>/twitter.com/}]\n"
  end

  it "use MiddlewareClass" do
    @app.use ExampleMiddlewareClass
    @app.trace.should == "use ExampleMiddlewareClass\n"
  end

  it "use MiddlewareClass, arg1, :some => 'options'" do
    @app.use(ExampleMiddlewareClass, 123.45, :some => :options){ }
    @app.trace.start_with?("use ExampleMiddlewareClass, 123.45, {:some=>:options}, &#<Proc:").should be_true
  end

  it "use MiddlewareClass && run @app" do
    @app.use ExampleMiddlewareClass
    @app.run @example_app
    @app.trace.should == "use ExampleMiddlewareClass\nrun SimpleApp<example_app>\n"
  end

  it "use MiddlewareClass :when => {} && run @app :when => {}"
  it "use MiddlewareClass, arg1, :arg2 => true, do ... end"

  describe "map '/foo' do" do
    it "run @app"
    describe "map '/bar' do" do
      it "run @app"
    end
  end

end
