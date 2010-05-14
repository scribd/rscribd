require 'uri'
require 'open-uri'

module Scribd
  
  # A document as shown on the Scribd website. API programs can upload documents
  # from files or URLs, tag them, and change their settings. An API program can
  # access any document, but it can only modify documents owned by the logged-in
  # user.
  #
  # To upload a new document to Scribd, you must create a new {Document}
  # instance, set the @file@ attribute to the file's path, and then save the
  # document:
  #
  # <pre><code>
  # doc = Scribd::Document.new
  # doc.file = '/path/or/URL/of/file.txt'
  # doc.save
  # </code></pre>
  #
  # You can do this more simply with one line of code:
  #
  # <pre><code>doc = Scribd::Document.create :file => '/path/or/URL/of/file.txt'</code></pre>
  #
  # If you are uploading a file that does not have an extension (like ".txt"),
  # you need to specify the @type@ attribute as well:
  #
  # <pre><code>doc = Scribd::Document.upload :file => 'CHANGELOG', :type => 'txt'</code></pre>
  #
  # Aside from these two attributes, you can set other attributes that affect
  # how the file is displayed on Scribd. See the API documentation online for a
  # list of attributes.
  #
  # These attributes can be accessed or changed directly
  # (@doc.title = 'Title'@). You must save a document after changing its
  # attributes in order for those changes to take effect. Not all attributes can
  # be modified; see the API documentation online for details.
  #
  # A document can be associated with a Scribd::User via the @owner@ attribute.
  # This is not always the case, however. {Document Documents} retrieved from
  # the {.find} method will not be associated with their owners.
  #
  # The @owner@ attribute is read/write, however, changes made to it only apply
  # _before_ the document is saved. Once it is saved, the owner is set in stone
  # and cannot be modified:
  #
  # <pre><code>
  # doc = Scribd::Document.new :file => 'test.txt'
  # doc.user = Scribd::User.signup(:username => 'newuser', :password => 'newpass', :email => 'your@email.com')
  # doc.save #=> Uploads the document as "newuser", regardless of who the Scribd API user is
  # doc.user = Scribd::API.instance.user #=> raises NotImplementedError
  #</code></pre>
  #
  # h2. Special attributes
  #
  # Normally any attributes other than @file@ and @type@ are sent to and dealt
  # by the API; however, there are a few attributes you can set on an instance
  # that have special meaning:
  #
  # | @thumbnail@ | Set this to the path to, a @File@ object for, or the URL string for an image file you want to act as the document's thumbnail. Note that for URLs, the thumbnail will be downloaded to memory before being transmitted to the Scribd API server. |
  
  class Document < Resource
    
    # Creates a new, unsaved document with the given attributes. The document
    # must be saved before it will appear on the website.
    #
    # @param [Hash] options The document's attributes.
    
    def initialize(options={})
      super
      @download_urls = Hash.new
      if options[:xml] then
        load_attributes(options[:xml])
        @attributes[:owner] = options[:owner]
        @saved = true
        @created = true
      else
        @attributes = options
      end
    end
    
    # For document objects that have not been saved for the first time, uploads
    # the document, sets its attributes, and saves it. Otherwise, updates any
    # changed attributes and saves it. Returns true if the save completed
    # successfully. Throws an exception if save fails.
    #
    # For first-time saves, you must have specified a @file@ attribute. This can
    # either be a local path to a file, or an HTTP, HTTPS, or FTP URL. In either
    # case, the file at that location will be uploaded to create the document.
    #
    # If you create a document, specify the @file@ attribute again, and then
    # save it, Scribd replaces the existing document with the file given, while
    # keeping all other properties (title, description, etc.) the same, in a
    # process called _revisioning_.
    #
    # You must specify the @type@ attribute alongside the @file@ attribute if
    # the file's type cannot be determined from its name.
    #
    # @raise [Timeout] If the connection is slow or inaccessible.
    # @raise [Scribd::ResponseError] If a remote problem occurs.
    # @raise [Scribd::PrivilegeError] If you try to upload a new revision for a
    # document with no associated user (i.e., one retrieved from the {.find}
    # method).
    # @return [true, false] Whether or not the upload was successful.
    
    def save
      if not created? and @attributes[:file].nil? then
        raise "'file' attribute must be specified for new documents"
      end
      
      if created? and @attributes[:file] and (@attributes[:owner].nil? or @attributes[:owner].session_key.nil?) then
        raise PrivilegeError, "The current API user is not the owner of this document"
      end

      # Make a request form
      response = nil
      fields = @attributes.dup
      fields.delete :thumbnail
      fields[:session_key] = fields.delete(:owner).session_key if fields[:owner]
      if file = @attributes[:file] then
        fields.delete :file
        is_file_object = file.is_a?(File)
        file_path = is_file_object ? file.path : file
        ext = File.extname(file_path).gsub(/^\./, '')
        ext = nil if ext == ''
        fields[:doc_type] = fields.delete(:type)
        fields[:doc_type] ||= ext
        fields[:doc_type].downcase! if fields[:doc_type]
        fields[:rev_id] = fields.delete(:doc_id)

        begin
          uri = URI.parse @attributes[:file]
        rescue URI::InvalidURIError
          uri = nil # Some valid file paths are not valid URI's (but some are)
        end
        if uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS or uri.kind_of? URI::FTP then
          fields[:url] = @attributes[:file]
          response = API.instance.send_request 'docs.uploadFromUrl', fields
        elsif uri.kind_of? URI::Generic or uri.nil? then
          file_obj = is_file_object ? file : File.open(file, 'rb')
          fields[:file] = file_obj
          response = API.instance.send_request 'docs.upload', fields
          file_obj.close unless is_file_object
        end
      end
      
      fields = @attributes.dup # fields is what we send to the server

      if response then
        # Extract our response
        xml = response.get_elements('/rsp')[0]
        load_attributes(xml)
        @created = true
      end

      if thumb = fields.delete(:thumbnail) then
        begin
          uri = URI.parse(thumb)
        rescue URI::InvalidURIError
          uri = nil
        end

        file = nil
        if uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS) or uri.kind_of?(URI::FTP) then
          file = open(uri)
        elsif uri.kind_of?(URI::Generic) or uri.nil? then
          file = thumb.kind_of?(File) ? thumb : File.open(thumb, 'rb')
        end

        API.instance.send_request('docs.uploadThumb', :file => file, :doc_id => self.id)
        file.close
      end
      
      fields.delete :access if fields[:file] # when uploading a doc, don't send access twice
      fields.delete :file
      fields.delete :type
      fields.delete :conversion_status
      
      changed_attributes = fields.dup # changed_attributes is what we will stick into @attributes once we update remotely
      
      fields[:session_key] = fields[:owner].session_key if fields[:owner]
      changed_attributes[:owner] ||= API.instance.user
      fields[:doc_ids] = self.id
      
      fields.delete :owner
      
      API.instance.send_request('docs.changeSettings', fields)
      
      @attributes.update(changed_attributes)
      
      @saved = true
      return true
    end
    
    # Quickly updates an array of documents with the given attributes. The
    # documents can have different owners, but all of them must be modifiable.
    #
    # @param [Array<Scribd::Document>] docs An array of documents to update.
    # @param [Hash] options The attributes to assign to all of those documents.
    # @raise [ArgumentError] If an invalid value for @docs@ is given.
    # @raise [ArgumentError] If an invalid value for @options@ is given.
    # @raise [ArgumentError] If one or more documents cannot be modified because
    # it has no owner (e.g., it was retrieved from a call to {.find}).
    
    def self.update_all(docs, options)
      raise ArgumentError, "docs must be an array" unless docs.kind_of? Array
      raise ArgumentError, "docs must consist of Scribd::Document objects" unless docs.all? { |doc| doc.kind_of? Document }
      raise ArgumentError, "You can't modify one or more documents" if docs.any? { |doc| doc.owner.nil? }
      raise ArgumentError, "options must be a hash" unless options.kind_of? Hash
      
      docs_by_user = docs.inject(Hash.new { |hash, key| hash[key] = Array.new }) { |hash, doc| hash[doc.owner] << doc; hash }
      docs_by_user.each { |user, doc_list| API.instance.send_request 'docs.changeSettings', options.merge(:doc_ids => doc_list.collect(&:id).join(','), :session_key => user.session_key) }
    end

    # @overload find(options={})
    #   This method is called with a hash of options to documents by their
    #   content. You must at a minimum supply a @query@ option, with a string
    #   that will become the full-text search query. For a list of other
    #   supported options, please see the online API documentation.
    #
    #   Documents retrieved by this method have no {User} stored in their
    #   @owner@ attribute; in other words, they cannot be modified.
    #
    #   @param [Hash] options Options for the search.
    #   @option options [String] :query The search query (required).
    #   @option options [Fixnum] :limit An alias for the @num_results@ option.
    #   @option options [Fixnum] :offset An alias for the @num_start@ option.
    #   @return [Array<Scribd::Document>] An array of documents found.
    #   @example
    #     Scribd::Document.find(:all, :query => 'cats and dogs', :limit => 10)
    #
    # @overload find(id, options={})
    #   Passing in simply a numerical ID loads the document with that ID. You
    #   can pass additional options as defined in the API documentation.
    #
    #   For now only documents that belong to the current user can be accessed
    #   in this manner.
    #
    #   @param [Fixnum] id The Scribd ID of the document to locate.
    #   @param [Hash] options Options to pass to the API find method.
    #   @return [Scribd::Document] The document found.
    #   @return [nil] If nothing was found.
    #   @example
    #     Scribd::Document.find(108196)
    #
    # @raise [ArgumentError] If neither of the two correct argument forms is
    # provided.
    
    def self.find(options={})
      doc_id = options.kind_of?(Integer) ? options : nil
      raise ArgumentError, "You must specify a query or document ID" unless doc_id or (options.kind_of?(Hash) and options[:query])
      
      if doc_id then
        response = API.instance.send_request('docs.getSettings', :doc_id => doc_id)
        return Document.new(:xml => response.elements['/rsp'])
      else
        options[:num_results] = options[:limit]
        options[:num_start] = options[:offset]
        response = API.instance.send_request('docs.search', options)
        documents = []
        response.elements['/rsp/result_set'].elements.each do |doc|
          documents << Document.new(:xml => doc)
        end
        return documents
      end
    end

    # Returns featured documents found in a given with given options.
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
    #   Scribd::Document.featured(:scope => 'hot', :limit => 10)

    def self.featured(options = {})
      response = API.instance.send_request('docs.featured', options)
      documents = []
      response.elements['/rsp/result_set'].elements.each do |doc|
        documents << Document.new(:xml => doc)
      end
      return documents
    end

    # Returns documents found by the Scribd browser with given options. The
    # browser provides documents suitable for a browse page.
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
    #   Scribd::Document.browse(:sort => 'views', :limit => 10)
    # @see Scribd::Category#browse

    def self.browse(options = {})
      response = API.instance.send_request('docs.browse', options)
      documents = []
      response.elements['/rsp/result_set'].elements.each do |doc|
        documents << Document.new(:xml => doc)
      end
      return documents
    end

    class << self
      alias_method :upload, :create
    end

    # Returns the conversion status of this document. When a document is
    # uploaded it must be converted before it can be used. The conversion is
    # non-blocking; you can query this method to determine whether the document
    # is ready to be displayed.
    #
    # For a full list of conversion statuses, see the online API documentation.
    #
    # Unlike other properties of a document, this is retrieved from the server
    # every time it's queried.
    #
    # @return [String] The document's conversion status.
    
    def conversion_status
      response = API.instance.send_request('docs.getConversionStatus', :doc_id => self.id)
      response.elements['/rsp/conversion_status'].text
    end

    # Returns the document read count. This is only retrieved from the API
    # server the first time it's queried unless @force@ is set to @true@.
    #
    # @param [Hash] options A hash of options.
    # @option options [true, false] :force If true, clears the local cache for
    # this value and re-retrieves it from the API server.
    # @return [String] The number of reads this document has received.

    def reads(options = {})
      if @reads.nil? || options[:force]
        response = API.instance.send_request('docs.getStats', :doc_id => self.id)
        @reads = response.elements['/rsp/reads'].text
      end
      @reads
    end

    # Deletes a document.
    #
    # @return [true, false] Whether or not the document was successfully
    # deleted.
    
    def destroy
      response = API.instance.send_request('docs.delete', :doc_id => self.id)
      return response.elements['/rsp'].attributes['stat'] == 'ok'
    end
    
    # Grants a user access to this document.
    #
    # @param [String] user_identifier The user identifier as used in your embed
    # code.
    # @see Scribd::Security.grant_access
    
    def grant_access(user_identifier)
      Scribd::Security.grant_access user_identifier, self
    end
    
    # Revokes access to this document from a user.
    #
    # @param [String] user_identifier The user identifier as used in your embed
    # code.
    # @see Scribd::Security.revoke_access
    
    def revoke_access(user_identifier)
      Scribd::Security.revoke_access user_identifier, self
    end
    
    # @return [Array<String>] A list of user identifiers that have access to
    # this document.
    # @see Scribd::Security.document_access_list
    
    def access_list
      Scribd::Security.document_access_list(self)
    end
    
    # @return The @document_id@ attribute.
    
    def id
      self.doc_id
    end

    # @private
    def owner=(newuser)
      # don't allow them to set the owner if the document is saved
      saved? ? raise(NotImplementedError, "Cannot change a document's owner once the document has been saved") : super
    end
    
    # Retrieves a document's download URL. You can provide a format for the
    # download. Valid formats are listed in the online API documentation.
    #
    # If you do not provide a format, the link will be for the document's
    # original format.
    #
    # @param [String] format The download format.
    # @return [String] The download URL.
    
    def download_url(format='original')
      @download_urls[format] ||= begin
        response = API.instance.send_request('docs.getDownloadUrl', :doc_id => self.id, :doc_type => format)
        response.elements['/rsp/download_link'].cdatas.first.to_s
      end
    end
  end
end
