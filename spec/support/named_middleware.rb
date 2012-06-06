# NamedMiddleware is a middleware that has a name and does nothing.
# Just for testing / debugging.
class NamedMiddleware
  attr_accessor :name

  def initialize(app, name = nil)
    @app = app
    self.name = name
  end

  def to_s
    "#{self.class.name}<#{name || object_id}>"
  end

  def call(env)
    @app.call(env)
  end
end
