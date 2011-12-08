# @private
class Hash
   # Taken from Rails, with appreciation to DHH
   def stringify_keys
     inject({}) do |options, (key, value)|
       options[key.to_s] = value
       options
     end
   end unless method_defined?(:stringify_keys)
   
   def compact!
     delete_if { |key, val| val.nil? }
   end
   
   def delete_keys(*keys)
     delete_if { |key, value| keys.include? key }
   end
   
end

# @private
class Array
  def to_hsh
    inject({}) { |hash, (key, value)| hash[key] = value; hash }
  end
end
