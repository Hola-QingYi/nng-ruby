# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Run examples'
task :examples do
  Dir.glob('examples/*.rb').each do |file|
    puts "\n=== Running #{file} ==="
    system("ruby #{file}")
  end
end

desc 'Generate YARD documentation'
task :yard do
  require 'yard'
  YARD::Rake::YardocTask.new
end
