# Wraps the response text in provided text (default: "*")
class ResponseWrapperMiddleware
  def initialize(app, text = "*", options = nil)
    @app = app
    @text = text
    @options = options || {}
    @options[:times] ||= 1
  end

  def text
    @text * @options[:times]
  end

  def call(env)
    status, headers, body_parts = @app.call(env)
    body = ""
    body_parts.each {|part| body << part }
    body = "#{text}#{body}#{text}"
    headers["Content-Length"] = body.length.to_s
    [status, headers, [body]]
  end
end
