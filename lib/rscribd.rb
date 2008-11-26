#!/usr/bin/env ruby

module Scribd # :nodoc:
end

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end unless method_defined?(:to_proc)
end

class Hash #:nodoc:
   # Taken from Rails, with appreciation to DHH
   def stringify_keys
     inject({}) do |options, (key, value)|
       options[key.to_s] = value
       options
     end
   end unless method_defined?(:stringify_keys)
end

class Array #:nodoc:
  def to_hsh
    h = Hash.new
    each { |k, v| h[k] = v }
    h
  end
end

# The reason these files have such terrible names is so they don't conflict with
# files in Rails's app/models directory; Rails seems to prefer loading those
# when require is called.
require 'scribdmultiparthack'
require 'scribderrors'
require 'scribdapi'
require 'scribdresource'
require 'scribddoc'
require 'scribduser'
