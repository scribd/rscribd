require 'bundler'
require 'rspec/core/rake_task'
require 'yard'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

desc 'Generate YARD documentation.'
YARD::Rake::YardocTask.new(:doc) do |rdoc|
  rdoc.options << '-o' << 'doc'
  rdoc.options << "--title" << "RScribd Documentation".inspect
  rdoc.options << '--charset' << 'utf-8'
  rdoc.options << '-r' << 'README'
  rdoc.options << '--protected' << '--no-private'
  rdoc.options << '--markup' << 'textile'
  rdoc.files << "lib/**/*.rb"
end