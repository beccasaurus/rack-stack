require "spec_helper"

describe RackStack, "#trace" do

  class MiddlewareToTrace
    def initialize(app) end
    def call(env) end
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
    @app.use MiddlewareToTrace
    @app.trace.should == "use MiddlewareToTrace\n"
  end

  it "use MiddlewareClass, arg1, :some => 'options'" do
    @app.use(MiddlewareToTrace, 123.45, :some => :options){ }
    @app.trace.start_with?("use MiddlewareToTrace, 123.45, {:some=>:options}, &#<Proc:").should be_true
  end

  it "use MiddlewareClass && run @app" do
    @app.use MiddlewareToTrace
    @app.run @example_app
    @app.trace.should == "use MiddlewareToTrace\nrun SimpleApp<example_app>\n"
  end

  it "use MiddlewareClass :when => {} && run @app :when => {}" do
    @app.run @example_app, :when => { :host => /twitter.com/ }
    @app.use MiddlewareToTrace, :when => { :host => "www.foo.com" }
    @app.trace.should == clean_trace(%{
      use MiddlewareToTrace, when: [{:host=>\"www.foo.com\"}]
      run SimpleApp<example_app>, when: [{:host=>/twitter.com/}]
    })
  end

  it "use MiddlewareClass, arg1, :arg2 => true, do ... end" do
    @app.use MiddlewareToTrace, 123.45, ["hello", "world"], :some => :options, :when => { :host => /twitter.com/ } do end
    @app.trace.start_with?("use MiddlewareToTrace, 123.45, [\"hello\", \"world\"], {:some=>:options}, &#<Proc").should be_true
    @app.trace.end_with?(">, when: [{:host=>/twitter.com/}]\n").should be_true
  end

  describe "map '/foo', :when => {}" do
    it "run @app" do
      @app.map "/foo", :when => { :host => /twitter.com/ } do
        run simple_app(:foo_app), :when => { :path_info => "/foo" }
      end

      @app.trace.should == clean_trace(%{
        map "/foo", when: [{:host=>/twitter.com/}] do
          run SimpleApp<foo_app>, when: [{:path_info=>"/foo"}]
        end
      }, :indent => 8)
    end
  end

  describe "map '/foo' do" do
    it "run @app" do
      @app.map "/foo" do
        run simple_app(:foo_app)
      end

      @app.trace.should == clean_trace(%{
        map "/foo" do
          run SimpleApp<foo_app>
        end
      }, :indent => 8)
    end

    describe "map '/bar' do" do
      it "run @app" do
        @app.map "/foo" do
          map "/bar" do
            run simple_app(:bar_app)
          end
          run simple_app(:foo_app)
        end

      @app.trace.should == clean_trace(%{
        map "/foo" do
          map "/bar" do
            run SimpleApp<bar_app>
          end
          run SimpleApp<foo_app>
        end 
      }, :indent => 8)
      end
    end
  end
end
