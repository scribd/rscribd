module Scribd
  
  # Contains methods for working with iPaper Secure. For more information about
  # iPaper Secure, see the online API documentation.
  
  module Security
    
    # Grants a user access to a {Document}. The user is referenced by his
    # identifier (as used in the iPaper Secure embed code). If no document is
    # provided, globally grants this user access to all documents.
    #
    # @param [String] user_identifier The user identifier as used in your embed
    # code. (See the online iPaper Secure documentation.)
    # @param [Scribd::Document, #to_i, nil] document If @nil@, globally grants
    # this user access to all documents. Otherwise, grants this user access
    # to one document specified by ID or {Document} instance.
    # @raise [ArgumentError] If an invalid value for @document@ is provided.
    # @see Scribd::Document#grant_access
    
    def self.grant_access(user_identifier, document=nil)
      set_access user_identifier, true, document
    end
    
    # Revokes from a user access to a {Document}. The user is referenced by his
    # identifier (as used in the iPaper Secure embed code). If no document is
    # provided, globally revokes access to all documents from this user.
    #
    # @param [String] user_identifier The user identifier as used in your embed
    # code. (See the online iPaper Secure documentation.)
    # @param [Scribd::Document, #to_i, nil] document If @nil@, globally revokes
    # access to all documents from this user. Otherwise, revokes access to one
    # document specified by ID or {Document} instance.
    # @raise [ArgumentError] If an invalid value for @document@ is provided.
    # @see Scribd::Document#revoke_access
    
    def self.revoke_access(user_identifier, document=nil)
      set_access user_identifier, false, document
    end
    
    # Sets whether a user has access to a {Document}. The user is referenced by
    # his identifier (as used in the iPaper Secure embed code). If no document
    # is provided, globally sets access to all documents for this user.
    #
    # @param [String] user_identifier The user identifier as used in your embed
    # code. (See the online iPaper Secure documentation.)
    # @param [true, false] access_allowed If @true@, grants access; if @false@,
    # revokes access.
    # @param [Scribd::Document, #to_i, nil] document If @nil@, globally sets
    # access to all documents for this user. Otherwise, sets access to one
    # document specified by ID or {Document} instance.
    # @raise [ArgumentError] If an invalid value for @document@ is provided.
    
    def self.set_access(user_identifier, access_allowed, document=nil)
      allow_value = (access_allowed ? 1 : 0)
      
      if document.nil? then
        API.instance.send_request('security.setAccess', :user_identifier => user_identifier, :allowed => allow_value)
        return
      end
      
      API.instance.send_request('security.setAccess', :user_identifier => user_identifier, :allowed => allow_value, :doc_id => (
        if document.kind_of?(Scribd::Document) then
          document.id
        elsif document.respond_to?(:to_i) then
          document.to_i
        else
          raise ArgumentError, "document must be a Scribd::Document, a document ID, or nil"
        end
      ))
    end
    
    # Returns a list of user identifiers that are allowed to access a given
    # document. See the iPaper Secure online documentation for more information.
    #
    # @param [Scribd::Document, Fixnum] document Either a document instance or
    # document ID.
    # @return [Array<String>] An array of user identifiers.
    # @see Scribd::Document#access_list
    
    def self.document_access_list(document)
      response = API.instance.send_request('security.getDocumentAccessList', :doc_id => (document.kind_of?(Scribd::Document) ? document.id : document))
      acl = Array.new
      response.get_elements('/rsp/resultset/result/user_identifier').each { |tag| acl << tag.text }
      return acl
    end
    
    # Returns a list of documents that a user can view. The user is identified
    # by his user identifier. See the iPaper Secure online documentation for
    # more information.
    #
    # @param [String] user_identifier The user identifier.
    # @return [Array<Scribd::Document>] An array of documents the user can
    # access.
    
    def self.user_access_list(user_identifier)
      response = API.instance.send_request('security.getUserAccessList', :user_identifier => user_identifier)
      acl = Array.new
      response.get_elements('/rsp/resultset/result').each { |tag| acl << Scribd::Document.new(:xml => tag) }
      return acl
    end
  end
end
