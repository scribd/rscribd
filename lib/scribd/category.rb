module Scribd
  
  # A category on Scribd. Categories group together {Document Documents} about
  # similar topics. Categories are represented as a two-way tree, with each
  # category having both a {#parent} and an array of {#children}.
  #
  # You can choose to load categories with or without their children using the
  # {.all} method. If you load categories with their children, each parent will
  # have its {#children} attribute set. Otherwise, calling {#children} on a
  # category will induce another network call.
  
  class Category < Resource
    # @return [Scribd::Category] The parent of this category.
    # @return [nil] If this is a top-level category.
    attr_reader :parent
    
    # @private
    def initialize(options)
      super
      @children_preloaded = false
      if options[:xml] then
        children_xml = options[:xml].get_elements('subcategories').first
        if children_xml and not children_xml.children.empty?
          @children = Array.new
          children_xml.get_elements('subcategory').each do |child_xml|
            children << Category.new(:xml => child_xml, :parent => self)
          end
          @children_preloaded = true
        end
        options[:xml].delete(children_xml) if children_xml
        
        load_attributes(options[:xml])
        @parent = options[:parent]
        @saved = true
        @created = true
      else
        raise "Categories cannot be created, only retrieved."
      end
    end
    
    # @return [true, false] True if this @Category@ has its children preloaded.
    # @see #children
    
    def children_preloaded?
      @children_preloaded
    end
    
    # Returns an array of top-level categories. These categories will have their
    # {#children} attributes set if @include_children@ is @true@.
    #
    # @param [true, false] include_children If @true@, child categories will be
    # loaded for each top-level category. If @false@, only top-level categories
    # will be loaded.
    # @return [Array<Scribd::Category>] All top-level categories. If
    # @include_children@ is @true@, each of these categories will have its
    # @children@ attribute pre-loaded.
    
    def self.all(include_children=false)
      response = include_children ? API.instance.send_request('docs.getCategories', :with_subcategories => true) : API.instance.send_request('docs.getCategories')
      categories = Array.new
      response.get_elements('/rsp/result_set/result').each do |res|
        categories << Category.new(:xml => res)
      end
      return categories
    end
    
    # Returns a list of the categories whose parent is this category.
    #
    # *If the receiver has preloaded its children* (in other words, it came from
    # a call to {.all .all(true)}), this method makes no network call.
    #
    # *If the receiver has not preloaded its children* (in other words, it came
    # from a call to {.all .all(false)}), _each_ invocation of this method will
    # make a new network call.
    #
    # @return [Array<Scribd::Category>] The child categories of this category.
    
    def children
      return @children if @children
      response = API.instance.send_request('docs.getCategories', :category_id => self.id)
      children = Array.new
      response.get_elements('/rsp/result_set/result').each do |res|
        children << Category.new(:xml => res)
      end
      return children
    end
    
    # Returns documents found by the Scribd browser with given options, all
    # categorized under this category. The browser provides documents suitable
    # for a browse page.
    #
    # This method is called with a hash of options. For a list of supported
    # options, please see the online API documentation.
    #
    # Documents returned from this method will have their @owner@ attributes set
    # to @nil@ (i.e., they are read-only).
    #
    # @param [Hash] options Options to pass to the API find method.
    # @return [Array<Scribd::Document>] An array of documents found.
    # @example
    #   category.browse(:sort => 'views', :category_id => 1, :limit => 10)
    
    def browse(options={})
      response = API.instance.send_request('docs.browse', options.merge(:category_id => self.id))
      documents = []
      response.elements['/rsp/result_set'].elements.each do |doc|
        documents << Document.new(:xml => doc)
      end
      return documents
    end
  end
end
