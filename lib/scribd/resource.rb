module Scribd  
  class Resource
    attr_reader :attributes, :saved, :created
    alias :saved? :saved
    alias :created? :created
    
    def self.build_collection(response, options = {})
      set = if response.xpath('/rsp/result_set/result').empty?
        response.xpath('/rsp/resultset/result')
      else
        response.xpath('/rsp/result_set/result')
      end
      
      set.map { |xml| new options.merge(:xml => xml) }
    end
    
    def self.create(options={})
      obj = new(options)
      obj.save
      obj
    end
    
    def self.find(options)
      raise NotImplementedError, "Cannot find #{self.class.to_s} objects"
    end
    
    def initialize(options={})
      @saved = @created = false
      @attributes = options
      
      build
    end

    def scribd_id
      @attributes[:id]
    end
    
    def save
      raise NotImplementedError, "Cannot save #{self.class.to_s} objects"
    end
    
    def destroy
      raise NotImplementedError, "Cannot destroy #{self.class.to_s} objects"
    end
    
    def read_attribute(attribute)
      @attributes[attribute.to_sym]
    end
        
    def write_attribute(attribute, value)      
      @attributes[attribute.to_sym] = value
    end

    def method_missing(method, *args)
      method.to_s =~ /^(\w+)=$/ ? write_attribute($1, args.first) : read_attribute(method)
    end
    
    protected
    def build
      if xml
        load_attributes xml
        @saved = @created = true
      end
    end
    
    private
    def load_attributes(xml)
      xml.children.select { |child| child.is_a? Nokogiri::XML::Element }.each do |node|
        write_attribute node.name, case node['type']
          when 'integer'; node.text.to_i
          when 'float'; node.text.to_f
          when 'symbol'; node.text.strip.to_sym
          else node.text.strip
        end
      end
    end
  end
end