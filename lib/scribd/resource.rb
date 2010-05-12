module Scribd
  
  # Describes a remote object that the Scribd API lets you interact with. All
  # such objects are modeled after the <tt>ActiveRecord</tt> ORM approach.
  #
  # The Resource superclass is never directly used; you will interact with
  # actual Scribd entities like Document and User, which inherit functionality
  # from this superclass.
  #
  # Objects have one or more attributes (also called fields) that can be
  # accessed directly through synonymous methods. For instance, if your resource
  # has an attribute +title+, you can get and set the title like so:
  #
  #  obj.title #=> "Title"
  #  obj.title = "New Title"
  #
  # The specific attributes that a Document or a User or any other resource has
  # are not stored locally. They are downloaded remotely whenever a resource is
  # loaded from the remote server. Thus, you can modify any attribute you want,
  # though it may or may not have any effect:
  #
  #  doc = Scribd::Document.find(:text => 'foo').first
  #  doc.self_destruct_in = 5.seconds #=> Does not produce error
  #  doc.save #=> Has no effect, since that attribute doesn't exist. Your document does not explode.
  #
  # As shown above, when you make changes to an attribute, these changes are not
  # immediately reflected remotely. They are only stored locally until such time
  # as save is called. When you call save, the remote object is updated to
  # reflect the changes you made in its API instance.
  
  class Resource
    
    # Initializes instance variables.
    
    def initialize(options={})
      @saved = false
      @created = false
      @attributes = Hash.new
    end
    
    # Creates a new instance with the given attributes, saves it immediately,
    # and returns it. You should call its created? method if you need to verify
    # that the object was saved successfully.
    
    def self.create(options={})
      obj = new(options)
      obj.save
      obj
    end
    
    # Throws NotImplementedError by default.
    
    def save
      raise NotImplementedError, "Cannot save #{self.class.to_s} objects"
    end
    
    # Throws NotImplementedError by default.
    
    def self.find(options)
      raise NotImplementedError, "Cannot find #{self.class.to_s} objects"
    end
    
    # Throws NotImplementedError by default.
    
    def destroy
      raise NotImplementedError, "Cannot destroy #{self.class.to_s} objects"
    end
    
    # Returns true if this document's attributes have been updated remotely, and
    # thus their local values reflect the remote values.
    
    def saved?
      @saved
    end
    
    # Returns true if this document has been created remotely, and corresponds
    # to a document on the Scribd website.
    
    def created?
      @created
    end
    
    # Returns the value of an attribute, referenced by string or symbol, or nil
    # if the attribute cannot be read.
    
    def read_attribute(attribute)
      raise ArgumentError, "Attribute must respond to to_sym" unless attribute.respond_to? :to_sym
      @attributes[attribute.to_sym]
    end
    
    # Returns a map of attributes to their values, given an array of attributes,
    # referenced by string or symbol. Attributes that cannot be read are
    # ignored.
    
    def read_attributes(attributes)
      raise ArgumentError, "Attributes must be listed in an Enumeration" unless attributes.kind_of?(Enumerable)
      raise ArgumentError, "All attributes must respond to to_sym" unless attributes.all? { |a| a.respond_to? :to_sym }
      keys = attributes.map(&:to_sym)
      values = @attributes.values_at(*keys)
      keys.zip(values).to_hsh
    end
    
    # Assigns values to attributes. Takes a hash that specifies the
    # attribute-value pairs to update. Does not perform a save. Non-writeable
    # attributes are ignored.
    
    def write_attributes(values)
      raise ArgumentError, "Values must be specified through a hash of attributes" unless values.kind_of? Hash
      raise ArgumentError, "All attributes must respond to to_sym" unless values.keys.all? { |a| a.respond_to? :to_sym }
      @attributes.update values.map { |k,v| [ k.to_sym, v ] }.to_hsh
    end
    
    # Gets or sets attributes for the resource. Any named attribute can be
    # retrieved for changed through a method call, even if it doesn't exist.
    # Such attributes will be ignored and purged when the document is saved:
    #
    #  doc = Scribd::Document.new
    #  doc.foobar #=> Returns nil
    #  doc.foobar = 12
    #  doc.foobar #=> Returns 12
    #  doc.save
    #  doc.foobar #=> Returns nil
    #
    # Because of this, no Scribd resource will ever raise NoMethodError.
    
    def method_missing(meth, *args)
      if meth.to_s =~ /(\w+)=/ then
        raise ArgumentError, "Only one parameter can be passed to attribute=" unless args.size == 1
        @attributes[$1.to_sym] = args[0]
      else
        @attributes[meth]
      end
    end
    
    # Pretty-print for debugging output of Scribd resources.
    
    def inspect #:nodoc:
      "#<#{self.class.to_s} #{@attributes.select { |k, v| not v.nil? }.collect { |k,v| k.to_s + '=' + v.to_s }.join(', ')}>"
    end
    
    private
    
    def load_attributes(xml)
      @attributes.clear
      xml.each_element do |element|
        text = if element.text.nil? or element.text.chomp.strip.empty? then
          (element.cdatas and not element.cdatas.empty?) ? element.cdatas.first.value : nil
        else
          element.text
        end
        
        @attributes[element.name.to_sym] = if element.attributes['type'] == 'integer' then
          text.to_i
        elsif element.attributes['type'] == 'float' then
          text.to_f
        elsif element.attributes['type'] == 'symbol' then
          text.to_sym
        else
          text
        end
      end
    end
  end
end
