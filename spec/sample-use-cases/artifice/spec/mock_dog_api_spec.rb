require "spec_helper"

describe MockDogApi do

  def dog_api
    @dog_api ||= MockDogApi.new
  end

  include Rack::Test::Methods
  alias app dog_api

  describe "/dogs.txt returns dog names delimited by newlines" do
    it "no dogs" do
      dog_api.names.should be_empty

      get "/dogs.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == ""
    end

    it "1 dog" do
      dog_api.names = %w[ Rover ]

      get "/dogs.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == "Rover"
    end

    it "many dogs" do
      dog_api.names = %w[ Rover Spot Rex ]

      get "/dogs.txt"
      last_response.status.should == 200
      last_response.content_type.should == "text/plain"
      last_response.body.should == "Rover\nSpot\nRex"
    end
  end
end
