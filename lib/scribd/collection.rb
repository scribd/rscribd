module Scribd
  
  # A collection on Scribd is a list of {Document Documents} created and
  # maintained by a user.
  #
  # @Collection@ instances and retrieved via the {User#collections} method.
  # @Collections@ cannot be modified using the gem or the API. You can, however,
  # {#add} and {#remove} {Document Documents} from a @Collection@.
  
  class Collection < Resource
    # @private
    DOCUMENT_MISSING_ERROR_CODE = 652
    # @private
    DOCUMENT_EXISTS_ERROR_CODE = 653
    
    # @return [Scribd::User] The user that created this collection.
    attr_reader :owner
    
    # @private
    def initialize(options={})
      super
      if options[:xml] then
        load_attributes(options[:xml])
        @owner = options[:owner]
        @saved = true
        @created = true
      else
        raise "Collections cannot be created, only retrieved."
      end
    end
    
    # Adds a {Document} to this collection.
    #
    # @param [Scribd::Document] document The document to add.
    # @param [true, false] ignore_if_exists If @false@, raises an exception if
    # the document is already in the collection.
    # @return [Scribd::Document] The @document@ parameter.
    # @raise [ArgumentError] If an invalid value for @document@ is provided.
    # @raise [Scribd::ResponseError] If @ignore_if_exists@ is set to @false@ and
    # the document already exists in the collection. See the online API
    # documentation for more information.
    
    def add(document, ignore_if_exists=true)
      raise ArgumentError, "You can only add Scribd::Documents to collections" unless document.kind_of?(Scribd::Document)
      begin
        API.instance.send_request 'docs.addToCollection', :collection_id => collection_id, :doc_id => document.id, :session_key => owner.session_key
      rescue ResponseError => err
        raise unless ignore_if_exists
        raise if err.code.to_i != DOCUMENT_EXISTS_ERROR_CODE
      end
      return document
    end
    
    # @see #add
    
    def <<(document)
      add document
    end
    
    # Removes a {Document} from this collection.
    #
    # @param [Scribd::Document] document The document to remove.
    # @param [true, false] ignore_if_missing If @false@, raises an exception if
    # the document is not in the collection.
    # @return [Scribd::Document] The @document@ parameter.
    # @raise [ArgumentError] If an invalid value for @document@ is provided.
    # @raise [Scribd::ResponseError] If @ignore_if_missing@ is set to @false@
    # and the document does not exist in the collection. See the online API
    # documentation for more information.
    
    def remove(document, ignore_if_missing=true)
      raise ArgumentError, "You can only remove Scribd::Documents from collections" unless document.kind_of?(Scribd::Document)
      begin
        API.instance.send_request 'docs.removeFromCollection', :collection_id => collection_id, :doc_id => document.id, :session_key => owner.session_key
      rescue ResponseError => err
        raise unless ignore_if_missing
        raise if err.code.to_i != DOCUMENT_MISSING_ERROR_CODE
      end
      return document
    end
    
    alias_method :delete, :remove
    
    # @return [String] The @collection_id@ attribute.
    
    def id
      collection_id
    end
    
    # @return [String] The @collection_name@ attribute.
    
    def name
      collection_name
    end
  end
end
