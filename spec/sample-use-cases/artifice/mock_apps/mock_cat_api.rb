# Sample Rack application that mocks a website's API.
class MockCatApi
  attr_accessor :names

  def initialize
    self.names = []
  end

  # /cats.txt returns text/plain cat names (delimited by newlines)
  def call(env)
    [200, {"Content-Type" => "text/plain"}, [names.join("\n")]]
  end
end
