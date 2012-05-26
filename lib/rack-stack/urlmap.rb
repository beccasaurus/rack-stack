class RackStack

  # @api private
  # Represents a Rack URLMap (eg. added via #map)
  class URLMap < Application
    attr_accessor :location, :rack_stack

    def initialize(name, location, options = nil, &block)
      self.name = name
      self.location = location
      self.rack_stack = RackStack.new(&block)

      add_request_matcher options[:when] if options
      add_request_matcher method(:path_matcher), :trace => false
      add_request_matcher method(:host_matcher), :trace => false if uri.absolute?
    end

    def call(env)
      env["SCRIPT_NAME"] = env["SCRIPT_NAME"] + uri.path.chomp("/")
      env["PATH_INFO"] = matching_path env["PATH_INFO"]

      rack_stack.call(env)
    end

    def uri
      URI.parse location
    end

    def path_matcher(request)
      matching_path(request.path_info) || location == "/"
    end

    def host_matcher(request)
      uri.host == request.env["HTTP_HOST"]
    end

    private

    def matching_path(path_info)
      pattern = Regexp.quote(uri.path.chomp("/")).gsub("/", "/+")
      regexp = Regexp.new("^#{pattern}(.*)", nil, "n")
      match = regexp.match path_info
      return match.captures.first if match
    end
  end
end
