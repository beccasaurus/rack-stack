class RackStack

  # @api private
  #
  # @example
  #   map "/path", when: { host: "some-host.com" } do
  #     use InnerMiddleware
  #     run CustomInnerApp.new, when: ->{ path_info =~ /custom/ }
  #     run InnerApp.new
  #   end
  class Map < RackStack

    attr_accessor :location
    
    def initialize(*args, &block)
      self.name = args.shift if args.first.is_a?(Symbol)
      self.location = args.shift

      configure &block

      add_request_matcher args.first[:when] if args.first
      add_request_matcher method(:path_matcher), false
      add_request_matcher method(:host_matcher), false if uri.absolute?
    end

    def map?
      true
    end

    def call(env)
      env["SCRIPT_NAME"] = env["SCRIPT_NAME"] + uri.path.chomp("/")
      env["PATH_INFO"] = matching_path env["PATH_INFO"]

      Responder.new(self, env).finish
    end

    def trace
      traced = "map"
      traced << " #{name.inspect}," if name
      traced << " #{location.inspect}"
      traced << ", when: #{matchers_to_trace.inspect}" if matchers_to_trace.any?
      traced << " do\n"
      traced << super.split("\n")[1..-2].join("\n") # ignore first/last RackStack.new/end lines
      traced << "\nend\n"
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

    def instance
      self
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
