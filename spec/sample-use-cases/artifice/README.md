# RackStack Sample Use Case: Artifice

In this sample, we have a DogsAndCats class that aggreggates 
data from 2 websites, http://dogs.com and http://cats.com.

In our tests for this class, we use Artifice to override Net::HTTP with a mounted 
RackStack (with dogs.com and cats.com mounted to mock those sites' APIs).

## Sample

From [dogs_and_cats_spec.rb](https://github.com/remi/rack-stack/blob/master/spec/sample-use-cases/artifice/spec/dogs_and_cats_spec.rb)

```ruby
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
```

`TODO`: Add example of busting out of Artifice by registering a Rack::Proxy as an app in the stack (a Rack::Proxy given access to the real Net::HTTP instance).  `app.skip.host "foo.com"`
