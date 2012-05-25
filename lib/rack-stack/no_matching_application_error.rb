class RackStack

  # Raised when a RackStack finds no matching application for a request.
  # Not raised if RackStack is being used as a middleware (or has a URLMap). TODO (? is this right ? spec what exactly happens with a URLMap/etc ...)
  class NoMatchingApplicationError < StandardError
    attr_accessor :stack, :env

    def initialize(attributes = {})
      self.stack = attributes[:stack]
      self.env = attributes[:env]
    end
  end
end
