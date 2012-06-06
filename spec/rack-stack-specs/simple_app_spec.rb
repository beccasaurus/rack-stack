require "spec_helper"

describe SimpleApp do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end

  class SimpleAppSampleSubclass < SimpleApp
  end

  it "SimpleApp.new { }" do
    @app = SimpleApp.new do
      write "Created!"
      self.status = 201
      self["Foo"] = "Bar"
    end

    get "/"

    last_response.body.should == "Created!"
    last_response.status.should == 201
    last_response["Foo"].should == "Bar"
  end

  it "SimpleApp.new {|response| }" do
    @app = SimpleApp.new do |response|
      response.write "Created!"
      response.status = 201
      response["Foo"] = "Bar"
    end

    get "/"

    last_response.body.should == "Created!"
    last_response.status.should == 201
    last_response["Foo"].should == "Bar"
  end

  it "SimpleApp.new {|request,response| }" do
    @app = SimpleApp.new do |request, response|
      response.write "Created #{request.params['name']}!"
      response.status = 201
      response["Foo"] = "Bar"
    end

    get "/", :name => "foo bar"

    last_response.body.should == "Created foo bar!"
    last_response.status.should == 201
    last_response["Foo"].should == "Bar"
  end

  it "SimpleApp.new :app_name" do
    app = SimpleApp.new :app_name
    app.name.should == :app_name
  end

  it "#to_s returns class name and instance #name" do
    app = SimpleApp.new :app_name
    app.to_s.should == "SimpleApp<app_name>"

    app = SimpleAppSampleSubclass.new :app_name
    app.to_s.should == "SimpleAppSampleSubclass<app_name>"
  end

end
