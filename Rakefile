desc 'Default: spec'
task :default => [:spec]

desc "Run specs"
task :spec => [:spec_rack_stack, :spec_rack_builder_compatibility]

desc 'Run tests (alias for spec)'
task :test => [:spec]

desc "Run RackStack test suite"
task :spec_rack_stack do
  sh "bundle exec rspec -Ispec/rack-stack-specs/ --color --format documentation --backtrace spec/rack-stack-specs/"
end

desc "Run Rack::Builder compatibility test suite"
task :spec_rack_builder_compatibility do
  sh "bundle exec ruby -Ilib spec/rack-builder-compatibility/rack_builder_compatibility_spec.rb"
end
