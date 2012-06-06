def clean_trace(trace, options = {})
  options[:indent] ||= 6
  trace.gsub(/^ {#{options[:indent]}}/, "").strip + "\n"
end
