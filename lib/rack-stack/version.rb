class RackStack
  begin
    old, $VERBOSE = $VERBOSE, nil
    VERSION = "0.1.0.pre"
  ensure
    $VERBOSE = old
  end
end
