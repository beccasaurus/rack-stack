class RackStack

  # Raised when a {RackStack} finds no matching application for a request.
  #
  # Not raised if RackStack has {RackStack#default_app} or includes a `#map`
  # statement.
  #
  # @see RackStack#call
  class NoMatchingApplicationError < StandardError

    # The {RackStack} dispatched to for the request that caused this
    # {NoMatchingApplicationError} to be raised.
    attr_accessor :rack_stack

    # The Rack environment Hash associated with the request that caused this
    # {NoMatchingApplicationError} to be raised.
    attr_accessor :env

    def initialize(attributes)
      self.rack_stack = attributes.fetch(:rack_stack)
      self.env = attributes.fetch(:env)
    end
  end
end
