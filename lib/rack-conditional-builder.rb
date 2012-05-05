module Rack
  class ConditionalBuilder

    def initialize(&block)
      if block.arity <= 0
        instance_eval &block
      else
        block.call self
      end
    end

    def use(*args, &middleware_block)
      name             = args.shift if args.first.is_a?(Symbol)
      middleware_class = args.shift

      stack.push Use.new(
        :name                 => name,
        :middleware_class     => middleware_class,
        :middleware_arguments => args,
        :middleware_block     => middleware_block
      )
    end

    def stack
      @stack ||= []
    end
  end
end

require "rack-conditional-builder/use"
