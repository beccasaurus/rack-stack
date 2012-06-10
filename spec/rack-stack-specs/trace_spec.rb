require "spec_helper"

describe RackStack, "#trace" do

  class MiddlewareToTrace
    def initialize(app, *args) end
    def call(env) end
  end

  before do
    @app = RackStack.new
    @example_app = SimpleApp.new(:example_app)
  end

  it "no components" do
    @app.trace.should == clean_trace(%{
      RackStack.new do
        end
    })
  end

  it "run @app" do
    @app.run @example_app
    @app.trace.should == clean_trace(%{
      RackStack.new do
        run SimpleApp<example_app>
      end
    })
  end

  it "run @app, when: <RequestMatcher>" do
    @app.run @example_app, :when => { :host => /twitter.com/ }

    @app.trace.should == clean_trace(%{
      RackStack.new do
        run SimpleApp<example_app>, when: [{:host=>/twitter.com/}]
      end
    })
  end

  it "use MiddlewareClass" do
    @app.use MiddlewareToTrace
    @app.trace.should == clean_trace(%{
      RackStack.new do
        use MiddlewareToTrace
      end
    })
  end

  it "use MiddlewareClass, arg1, :some => 'options'" do
    @app.use(MiddlewareToTrace, 123.45, :some => :options){ }
    @app.trace.should =~ /use MiddlewareToTrace, 123.45, {:some=>:options}, &#<Proc:/
  end

  it "use MiddlewareClass && run @app" do
    @app.use MiddlewareToTrace
    @app.run @example_app
    @app.trace.should == clean_trace(%{
      RackStack.new do
        use MiddlewareToTrace
        run SimpleApp<example_app>
      end
    })
  end

  it "use MiddlewareClass :when => {} && run @app :when => {}" do
    @app.run @example_app, :when => { :host => /twitter.com/ }
    @app.use MiddlewareToTrace, :when => { :host => "www.foo.com" }
    @app.trace.should == clean_trace(%{
      RackStack.new do
        use MiddlewareToTrace, when: [{:host=>\"www.foo.com\"}]
        run SimpleApp<example_app>, when: [{:host=>/twitter.com/}]
      end
    })
  end

  it "use MiddlewareClass, arg1, :arg2 => true, do ... end" do
    @app.use MiddlewareToTrace, 123.45, ["hello", "world"], :some => :options, :when => { :host => /twitter.com/ } do end
    @app.trace.should =~ /use MiddlewareToTrace, 123\.45, \[\"hello\", \"world\"], {:some=>:options}, &#<Proc/
    @app.trace.should =~ %r(>, when: \[{:host=>/twitter.com/}])
  end

  describe "map '/foo', :when => {}" do
    it "run @app" do
      @app.map "/foo", :when => { :host => /twitter.com/ } do
        run SimpleApp.new(:foo_app), :when => { :path_info => "/foo" }
      end

      @app.trace.should == clean_trace(%{
        RackStack.new do
          map "/foo", when: [{:host=>/twitter.com/}] do
            run SimpleApp<foo_app>, when: [{:path_info=>"/foo"}]
          end
        end
      }, :indent => 8)
    end
  end

  describe "map '/foo' do" do
    it "run @app" do
      @app.map "/foo" do
        run SimpleApp.new(:foo_app)
      end

      @app.trace.should == clean_trace(%{
        RackStack.new do
          map "/foo" do
            run SimpleApp<foo_app>
          end
        end
      }, :indent => 8)
    end

    describe "map '/bar' do" do
      it "run @app" do
        @app.map "/foo" do
          map "/bar" do
            run SimpleApp.new(:bar_app)
          end
          run SimpleApp.new(:foo_app)
        end

      @app.trace.should == clean_trace(%{
        RackStack.new do
          map "/foo" do
            map "/bar" do
              run SimpleApp<bar_app>
            end
            run SimpleApp<foo_app>
          end
        end
      }, :indent => 8)
      end
    end
  end
end
