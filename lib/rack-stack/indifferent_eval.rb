class RackStack

  # @api private
  # Provides {#indifferent_eval}.
  module IndifferentEval

    # If no arguments are passed to the given block, then the
    # block will be instance_eval'd against the given object (or self).
    #
    # If an argument is passed, however, then the given object (or self)
    # will be yielded to the given block.
    def indifferent_eval(object = self, &block)
      if block
        if block.arity <= 0
          object.instance_eval &block
        else
          block.call object
        end
      end
    end
  end
end
