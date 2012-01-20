module Scribd  
  class Category < Resource
    
    def self.all(include_children = false)
      build_collection API.request 'docs.getCategories', (include_children ? { :with_subcategories => true } : {})
    end
    
    def children
      return @children if @children
      Category.build_collection API.request 'docs.getCategories', :category_id => scribd_id
    end
    
    def browse(options={})
      Document.build_collection API.request 'docs.browse', options.merge(:category_id => scribd_id)
    end
    
    protected
    def build
      if xml
        children_xml = xml.at_xpath 'subcategories'
                
        if children_xml && !children_xml.children.empty?
          @children = children_xml.xpath('subcategory').map { |xml| Category.new :xml => xml, :parent => self }
        end
        
        xml.delete(children_xml) if children_xml
        
        super
      else
        raise "Categories cannot be created, only retrieved."
      end
    end
  end
end
