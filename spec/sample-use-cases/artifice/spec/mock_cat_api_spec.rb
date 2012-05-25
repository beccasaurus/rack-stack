require "spec_helper"

describe MockCatApi do

  def cat_api
    @cat_api ||= MockCatApi.new
  end

  include Rack::Test::Methods
  alias app cat_api

  describe "/cats.txt returns cat names delimited by newlines" do
    it "no cats" do
      cat_api.names.should be_empty

      get "/cats.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == ""
    end

    it "1 cat" do
      cat_api.names = %w[ Rover ]

      get "/cats.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == "Rover"
    end

    it "many cats" do
      cat_api.names = %w[ Rover Spot Rex ]

      get "/cats.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == "Rover\nSpot\nRex"
    end
  end
end
