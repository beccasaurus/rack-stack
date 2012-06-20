require "spec_helper"

describe MockCatApi do

  def cat_api
    @cat_api ||= MockCatApi.new
  end

  include Rack::Test::Methods
  alias app cat_api

  describe "/cats.xml returns cat names delimited by newlines" do
    it "no cats" do
      cat_api.names.should be_empty

      get "/cats.xml"
      last_response.status.should == 200
      last_response.content_type.should == "application/xml"
      last_response.body.should == ""
    end

    it "1 cat" do
      cat_api.names = %w[ Mittens ]

      get "/cats.xml"
      last_response.status.should == 200
      last_response.content_type.should == "application/xml"
      last_response.body.should == "<meow>Mittens</meow>"
    end

    it "many cats" do
      cat_api.names = %w[ Mittens Paws Patches ]

      get "/cats.xml"
      last_response.status.should == 200
      last_response.content_type.should == "application/xml"
      last_response.body.should == "<meow>Mittens</meow>\n<meow>Paws</meow>\n<meow>Patches</meow>"
    end
  end
end
