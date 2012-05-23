require "spec_helper"

describe RackStack, "#map" do
  include Rack::Test::Methods

  def app
    Rack::Lint.new @app
  end
end
