# encoding: utf-8
require "#{File.dirname(__FILE__)}/lib/scribd/version"

Gem::Specification.new do |s|
  s.name              = 'rscribd'
  s.summary           = 'Ruby client library for the Scribd API'
  s.description       = 'The official Ruby gem for the Scribd API. Scribd is a document-sharing website allowing people to upload and view documents online.'
  s.authors           = ["Tim Morgan", "Jared Friedman", "Mike Watts"]
  s.email             = 'api@scribd.com'
  s.homepage          = 'http://www.scribd.com/developers'
  
  s.version           = Scribd::VERSION::STRING
  s.platform          = Gem::Platform::RUBY

  s.extra_rdoc_files  = %w(README)
  s.files             = `git ls-files`.split("\n")
  s.require_paths     = %w(lib)
  s.rubyforge_project = 'rscribd'
  
  s.add_runtime_dependency 'mime-types'
  s.add_dependency 'nokogiri'
  s.add_dependency 'curb'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'webmock'
end

