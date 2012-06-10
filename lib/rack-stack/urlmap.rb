class RackStack

  # @api private
  # Represents a Rack URLMap (eg. added via #map)
  #
  # TODO even though this class is private, I feel like having the name URLMap might imply that you could actually try to use this class yourself as a URLMap implementation or something.  Maybe we should rename these classes back to being named after the statements to make it very clear that this is more like an AST for representing the stack layers than it is a standalone class ...
  class URLMap < Application

    attr_accessor :location
    
    attr_accessor :rack_stack

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

    def trace
      matchers = request_matchers.select(&:trace).map(&:matcher)

      traced = ""
      traced << "map"
      traced << " #{name.inspect}," if name
      traced << " #{location.inspect}"
      traced << ", when: #{matchers.inspect}" if matchers.any?
      traced << " do\n"
      traced << rack_stack.trace.gsub(/^/, "  ")
      traced << "end\n"
      traced
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
