#!/usr/bin/env ruby

# Container module for all classes in the RScribd gem.

module Scribd
end

require 'support/extensions'
require 'support/multipart_hack'
require 'scribd/errors'
require 'scribd/api'
require 'scribd/resource'
require 'scribd/category'
require 'scribd/collection'
require 'scribd/document'
require 'scribd/user'
require 'scribd/security'
