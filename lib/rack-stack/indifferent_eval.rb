class RackStack
  module IndifferentEval

    # If no arguments passed, instance eval, else yield to block.
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
