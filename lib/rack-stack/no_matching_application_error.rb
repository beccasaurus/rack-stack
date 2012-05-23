class RackStack
  class NoMatchingApplicationError < StandardError
    attr_accessor :stack, :env

    def initialize(attributes = {})
      self.stack = attributes[:stack]
      self.env = attributes[:env]
    end
  end
end
