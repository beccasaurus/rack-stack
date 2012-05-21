require "spec_helper"

class RackStack

  # request_matchers << RequestMatcher.new(options[:if])
  # request_matchers << RequestMatcher.new(options[:unless], :negate => true)
  describe RequestMatcher do

    describe "#result(env)" do
      it "returns true when condition matches"
      it "returns false when condition doens't match"

      context "when negate is set to true" do
        it "returns false when condition matches"
        it "returns true when condition doesn't match"
      end
    end

  end
end
