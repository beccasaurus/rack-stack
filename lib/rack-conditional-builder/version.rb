module Rack::ConditionalBuilder::Version
  begin
    old, $VERBOSE = $VERBOSE, nil
    VERSION = "0.1.0"
  ensure
    $VERBOSE = old
  end
end
