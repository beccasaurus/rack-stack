# Represents any layer in a RackStack, eg. RackApplication, RackMiddleware, or RackMap (could be just a RackApplication that has an extra RequestMatcher?)
class RackStack
  class RackComponent
    attr_accessor :name
  end
end
