module Scribd
  module Security
    
    class << self
      def grant_access(user_identifier, document=nil)
        set_access user_identifier, true, document
      end  
    
      def revoke_access(user_identifier, document=nil)
        set_access user_identifier, false, document
      end
    
      def set_access(user_identifier, access_allowed, document=nil)
        options = { :user_identifier => user_identifier, :allowed => (access_allowed ? 1 : 0) }
        options.merge! :doc_id => doc_id(document) if document
        
        API.request 'security.setAccess', options
      end
    
      def document_access_list(document)      
        response = API.request 'security.getDocumentAccessList', :doc_id => doc_id(document)
        response.xpath('/rsp/resultset/result/user_identifier').map &:text
      end
    
      def user_access_list(user_identifier)
        Document.build_collection API.request 'security.getUserAccessList', :user_identifier => user_identifier
      end
    
      def doc_id(document)
        if document.is_a? Scribd::Document; document.id
        elsif document.respond_to?(:to_i); document.to_i
        else raise ArgumentError, "document must be a Scribd::Document, a document ID, or nil"
        end
      end
    end
  end
end
