require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :spec

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run the code examples in spec"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/*_spec.rb"
end
