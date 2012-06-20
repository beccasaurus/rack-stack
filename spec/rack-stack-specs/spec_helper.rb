require "rack/stack"
require "rack/stack/simple_app"

require "rspec"
require "rack/test"
require "support/clean_trace"
require "support/response_wrapper_middleware"
require "support/named_middleware"

RSpec.configure do |config|
  config.before do
    RackStack.rack_builder_compatibility = false
  end
end
