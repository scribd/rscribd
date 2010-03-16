require 'rubygems'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rscribd"
    gemspec.summary = "Ruby client library for the Scribd API"
    gemspec.description = "The official Ruby gem for the Scribd API. Scribd is a document-sharing website allowing people to upload and view documents online."
    gemspec.email = "api@scribd.com"
    gemspec.homepage = "http://www.scribd.com/developers"
    gemspec.authors = [ "Tim Morgan", "Jared Friedman", "Mike Watts" ]
    
    gemspec.add_dependency 'mime-types'
    gemspec.add_development_dependency "rspec"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Verify gem specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/*.rb']
  t.spec_opts = [ '-cfs' ]
end
