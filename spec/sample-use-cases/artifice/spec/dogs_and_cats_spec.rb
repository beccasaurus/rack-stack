require "spec_helper"

describe DogsAndCats do

  def apps
    @apps ||= RackStack.new
  end

  before do
    apps.run :dogs, MockDogApi.new, :when => { :host => "dogs.com" }
    apps.run :cats, MockCatApi.new, :when => { :host => "cats.com" }

    Artifice.activate_with apps
  end

  describe "#fetch returns dog/cat names fetched from dogs/cats.com" do
    it "no animals" do
      apps.dogs.names.should == []
      apps.cats.names.should == []

      DogsAndCats.fetch.should == { :dog_names => [], :cat_names => [] }
    end

    it "no dogs" do
      apps.cats.names = ["Meowzers"]

      DogsAndCats.fetch.should == { :dog_names => [], :cat_names => %w[Meowzers] }
    end

    it "no cats" do
      apps.dogs.names = ["Rover", "Spot", "Rex"]

      DogsAndCats.fetch.should == { :dog_names => %w[Rover Spot Rex], :cat_names => [] }
    end

    it "dogs and cats" do
      apps.cats.names = ["Meowzers"]
      apps.dogs.names = ["Rover", "Spot", "Rex"]

      DogsAndCats.fetch.should == { :dog_names => %w[Rover Spot Rex], :cat_names => %w[Meowzers] }
    end
  end

end
