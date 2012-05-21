require "spec_helper"

class RackStack
  describe RackComponent do

    it "has a name" do
      component = RackComponent.new
      component.name = :usually_a_symbol
      component.name.should == :usually_a_symbol
    end

  end
end
