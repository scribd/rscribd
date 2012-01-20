require 'simplecov'
SimpleCov.add_filter '/spec/'
SimpleCov.start

require 'webmock/rspec'
require "#{File.dirname(__FILE__)}/../lib/rscribd"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.filter_run wip: true
  config.run_all_when_everything_filtered = true
  
  config.after do
    Scribd::API.reload
  end
end