module Scribd
  class Collection < Resource
    
    DOCUMENT_MISSING_ERROR_CODE = 652
    DOCUMENT_EXISTS_ERROR_CODE = 653    
    
    def id; collection_id end
    def name; collection_name end
    
    def add(document, ignore_error = true)
      action 'docs.addToCollection', document, ignore_error, DOCUMENT_EXISTS_ERROR_CODE, "You can only add Scribd::Documents to collections"
    end
    
    def <<(document)
      add document
    end
    
    def remove(document, ignore_error = true)
      action 'docs.removeFromCollection', document, ignore_error, DOCUMENT_MISSING_ERROR_CODE, "You can only remove Scribd::Documents from collections"
    end
    
    alias_method :delete, :remove
    
    protected
    def action(request_method, document, ignore_error, error_code, error_message)      
      raise ArgumentError, error_message unless document.is_a? Scribd::Document
      
      begin
        API.request request_method, :collection_id => collection_id, :doc_id => document.id, :session_key => owner.session_key
      rescue ResponseError => error
        raise if !ignore_error || error.code.to_i != error_code
      end
      
      document
    end
    
    def build
      xml ? super : raise("Collections cannot be created, only retrieved.")
    end
  end
end