module Rack
  class ConditionalBuilder::Use
    attr_accessor :name
    attr_accessor :middleware_class
    attr_accessor :middleware_arguments
    attr_accessor :middleware_block
    attr_accessor :middleware_instance

    def initialize(attributes = nil)
      if attributes
        attributes.each do |name, value|
          send("#{name}=", value)
        end
      end
    end
  end
end
