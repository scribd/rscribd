# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.new('rscribd', '0.1.1') do |p|
  p.rubyforge_name = 'rscribd'
  p.author = 'Jared Friedman'
  p.email = 'api@scribd.com'
  p.summary = 'Ruby client library for the Scribd API'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << [ 'mime-types', '>0.0.0' ]
  p.remote_rdoc_dir = ''
end

# vim: syntax=Ruby
