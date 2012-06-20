# Sample Rack application that mocks a website's API.
class MockCatApi
  attr_accessor :names

  def initialize
    self.names = []
  end

  # /cats.xml returns text/plain cat names (delimited by newlines)
  def call(env)
    body = names.map {|name| "<meow>#{name}</meow>" }.join("\n")

    [200, {"Content-Type" => "application/xml"}, [body]]
  end
end
