require 'open-uri'
require 'tempfile'
require 'digest/md5'
require 'nokogiri'
require 'curb'

$LOAD_PATH.unshift File.dirname(__FILE__)

require "scribd/request"
require "support/extensions"
require "scribd/errors"
require "scribd/resource"
require "scribd/user"
require "scribd/api"
require "scribd/category"
require "scribd/collection"
require "scribd/document"
require "scribd/security"

Scribd::API.reload
