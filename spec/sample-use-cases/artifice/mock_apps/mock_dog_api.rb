# Sample Rack application that mocks a website's API.
class MockDogApi
  attr_accessor :names

  def initialize
    self.names = []
  end

  # /dogs.txt returns text/plain dog names (delimited by newlines)
  def call(env)
    [200, {"Content-Type" => "text/plain"}, [names.join("\n")]]
  end
end
