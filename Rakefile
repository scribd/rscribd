require 'rubygems'
require 'hoe'
require 'spec/rake/spectask'

Hoe.new('rscribd', '1.0.1') do |p|
  p.rubyforge_name = 'rscribd'
  p.author = 'Jared Friedman, Tim Morgan'
  p.email = 'api@scribd.com'
  p.summary = 'Ruby client library for the Scribd API'
  p.description = p.paragraphs_of('README.txt', 3).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << [ 'mime-types', '>0.0.0' ]
  p.remote_rdoc_dir = ''
end

desc "Verify gem specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = [ '-cfs' ]
end

namespace :github do
  desc "Prepare for GitHub gem packaging"
  task :prepare do
    `rake debug_gem > rscribd.gemspec`
  end
end