# @private
class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end unless method_defined?(:to_proc)
end

# @private
class Hash
   # Taken from Rails, with appreciation to DHH
   def stringify_keys
     inject({}) do |options, (key, value)|
       options[key.to_s] = value
       options
     end
   end unless method_defined?(:stringify_keys)
end

# @private
class Array
  def to_hsh
    h = Hash.new
    each { |k, v| h[k] = v }
    h
  end
end
