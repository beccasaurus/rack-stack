require "open-uri"

# DogsAndCats fetches the current dog and cat names from dogs.com
# and cats.com and returns them as a Hash, eg. { :dog_names => [], :cat_names => }
class DogsAndCats
  def self.fetch
    { :dog_names => fetch_dog_names,
      :cat_names => fetch_cat_names }
  end

  def self.fetch_dog_names
    open("http://dogs.com/dogs.txt").read.split("\n")
  end

  def self.fetch_cat_names
    open("http://cats.com/cats.txt").read.split("\n").map do |text|
      text.match(%r{<meow>(.*)</meow>}).captures.first
    end
  end
end
