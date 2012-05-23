require "rspec/core/rake_task"

desc 'Default: run specs'
task :default => [:spec, :test_rack_builder_compatibility]

desc 'Run tests'
task :test => [:spec, :test_rack_builder_compatibility]

desc "Run specs"
RSpec::Core::RakeTask.new

desc "Test Rack::Builder compatibility"
task :test_rack_builder_compatibility do
  sh "bundle exec ruby -Ilib rack-builder-compatibility/rack_builder_compatibility_spec.rb"
end
