require 'uri'

module Scribd
  
  # A document as shown on the Scribd website. API programs can upload documents
  # from files or URL's, tag them, and change their settings. An API program can
  # access any document, but it can only modify documents owned by the logged-in
  # user.
  #
  # To upload a new document to Scribd, you must create a new Document instance,
  # set the +file+ attribute to the file's path, and then save the document:
  #
  #  doc = Scribd::Document.new
  #  doc.file = '/path/or/URL/of/file.txt'
  #  doc.save
  #
  # You can do this more simply with one line of code:
  #
  #  doc = Scribd::Document.create :file => '/path/or/URL/of/file.txt'
  #
  # If you are uploading a file that does not have an extension (like ".txt"),
  # you need to specify the +type+ attribute as well:
  #
  #  doc = Scribd::Document.upload :file => 'CHANGELOG', :type => 'txt'
  #
  # Aside from these two attributes, you can set other attributes that affect
  # how the file is displayed on Scribd. See the API documentation online for a
  # list of attributes, at
  # http://www.scribd.com/publisher/api?method_name=docs.search (consult the
  # "Result explanation" section).
  #
  # These attributes can be accessed or changed directly
  # (<tt>doc.title = 'Title'</tt>). You must save a document after changing its
  # attributes in order for those changes to take effect. Not all attributes can
  # be modified; see the API documentation online for details.
  #
  # A document can be associated with a Scribd::User via the +owner+ attribute.
  # This is not always the case, however. Documents retrieved from the find
  # method will not be associated with their owners.
  #
  # The +owner+ attribute is read/write, however, changes made to it only apply
  # _before_ the document is saved. Once it is saved, the owner is set in stone
  # and cannot be modified:
  #
  #  doc = Scribd::Document.new :file => 'test.txt'
  #  doc.user = Scribd::User.signup(:username => 'newuser', :password => 'newpass', :email => 'your@email.com')
  #  doc.save #=> Uploads the document as "newuser", regardless of who the Scribd API user is
  #  doc.user = Scribd::API.instance.user #=> raises NotImplementedError 
  
  class Document < Resource
    
    # Creates a new, unsaved document with the given attributes. The document
    # must be saved before it will appear on the website.
    
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
    # For first-time saves, you must have specified a +file+ attribute. This can
    # either be a local path to a file, or an HTTP, HTTPS, or FTP URL. In either
    # case, the file at that location will be uploaded to create the document.
    #
    # If you create a document, specify the +file+ attribute again, and then
    # save it, Scribd replaces the existing document with the file given, while
    # keeping all other properties (title, description, etc.) the same, in a
    # process called _revisioning_.
    #
    # This method can throw a +Timeout+ exception if the connection is slow or
    # inaccessible. A Scribd::ResponseError will be thrown if a remote problem
    # occurs. A Scribd::PrivilegeError will be thrown if you try to upload a new
    # revision for a document with no associated user (i.e., one retrieved from
    # the find method).
    #
    # You must specify the +type+ attribute alongside the +file+ attribute if
    # the file's type cannot be determined from its name.
    
    def save
      if not created? and @attributes[:file].nil? then
        raise "'file' attribute must be specified for new documents"
        return false
      end
      
      if created? and @attributes[:file] and (@attributes[:owner].nil? or @attributes[:owner].session_key.nil?) then
        raise PrivilegeError, "The current API user is not the owner of this document"
      end
      
      # Make a request form
      fields = @attributes.dup
      if @attributes[:file] then
        fields.delete :file
        ext = @attributes[:file].split('.').last unless @attributes[:file].index('.').nil?
        fields[:doc_type] = fields.delete(:type)
        fields[:doc_type] ||= ext
        fields[:doc_type].downcase! if fields[:doc_type]
        fields[:rev_id] = fields.delete(:doc_id)
      end
      fields[:session_key] = fields.delete(:owner).session_key if fields[:owner]
      response = nil
      
      if @attributes[:file] then
        uri = nil
        begin
          uri = URI.parse @attributes[:file]
        rescue URI::InvalidURIError
          uri = nil # Some valid file paths are not valid URI's (but some are)
        end
        if uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS or uri.kind_of? URI::FTP then
          fields[:url] = @attributes[:file]
          response = API.instance.send_request 'docs.uploadFromUrl', fields
        elsif uri.kind_of? URI::Generic or uri.nil? then
          File.open(@attributes[:file]) do |file|
            fields[:file] = file
            response = API.instance.send_request 'docs.upload', fields
          end
        end
      end
      
      fields = @attributes.dup # fields is what we send to the server

      if response then
        # Extract our response
        xml = response.get_elements('/rsp')[0]
        load_attributes(xml)
        @created = true
      end
      
      fields.delete :file
      fields.delete :type
      fields.delete :access
      
      changed_attributes = fields.dup # changed_attributes is what we will stick into @attributes once we update remotely
      
      fields[:session_key] = fields[:owner].session_key if fields[:owner]
      changed_attributes[:owner] ||= API.instance.user
      fields[:doc_ids] = self.id
      
      API.instance.send_request('docs.changeSettings', fields)
      
      @attributes.update(changed_attributes)
      
      @saved = true
      return true
    end
    
    # Quickly updates an array of documents with the given attributes. The
    # documents can have different owners, but all of them must be modifiable.
    
    def self.update_all(docs, options)
      raise ArgumentError, "docs must be an array" unless docs.kind_of? Array
      raise ArgumentError, "docs must consist of Scribd::Document objects" unless docs.all? { |doc| doc.kind_of? Document }
      raise ArgumentError, "You can't modify one or more documents" if docs.any? { |doc| doc.owner.nil? }
      raise ArgumentError, "options must be a hash" unless options.kind_of? Hash
      
      docs_by_user = docs.inject(Hash.new { |hash, key| hash[key] = Array.new }) { |hash, doc| hash[doc.owner] << doc; hash }
      docs_by_user.each { |user, doc_list| API.instance.send_request 'docs.changeSettings', options.merge(:doc_ids => doc_list.collect(&:id).join(','), :session_key => user.session_key) }
    end
    
    # === Finding by query
    #
    # This method is called with a scope and a hash of options to documents by
    # their content. You must at a minimum supply a +query+ option, with a
    # string that will become the full-text search query. For a list of other
    # supported options, please see the online API documentation at
    # http://www.scribd.com/publisher/api?method_name=docs.search
    #
    # The scope can be any value given for the +scope+ parameter in the above
    # website, or <tt>:first</tt> to return the first result only (not an array
    # of results).
    #
    # The +num_results+ option has been aliased as +limit+, and the +num_start+
    # option has been aliased as +offset+.
    #
    # Documents returned from this method will have their +owner+ attributes set
    # to nil.
    #
    #  Scribd::Document.find(:all, :query => 'cats and dogs', :limit => 10)
    #
    # === Finding by ID
    #
    # Passing in simply a numerical ID loads the document with that ID. You can
    # pass additional options as defined at
    # httphttp://www.scribd.com/publisher/api?method_name=docs.getSettings
    #
    #  Scribd::Document.find(108196)
    #
    # For now only documents that belong to the current user can be accessed in
    # this manner.
    
    def self.find(scope, options={})
      doc_id = scope if scope.kind_of?(Integer)
      raise ArgumentError, "You must specify a query or document ID" unless options[:query] or doc_id
      
      if doc_id then
        options[:doc_id] = doc_id
        response = API.instance.send_request('docs.getSettings', options)
        return Document.new(:xml => response.elements['/rsp'])
      else
        options[:scope] = scope == :first ? 'all' : scope.to_s
        options[:num_results] = options[:limit]
        options[:num_start] = options[:offset]
        response = API.instance.send_request('docs.search', options)
        documents = []
        response.elements['/rsp/result_set'].elements.each do |doc|
          documents << Document.new(:xml => doc)
        end
        return scope == :first ? documents.first : documents
      end
    end
    
    class << self
      alias_method :upload, :create
    end
    
    # Returns the conversion status of this document. When a document is
    # uploaded it must be converted before it can be used. The conversion is
    # non-blocking; you can query this method to determine whether the document
    # is ready to be displayed.
    #
    # The conversion status is returned as a string. For a full list of
    # conversion statuses, see the online API documentation at
    # http://www.scribd.com/publisher/api?method_name=docs.getConversionStatus
    #
    # Unlike other properties of a document, this is retrieved from the server
    # every time it's queried.
    
    def conversion_status
      response = API.instance.send_request('docs.getConversionStatus', :doc_id => self.id)
      response.elements['/rsp/conversion_status'].text
    end
    
    # Deletes a document. Returns true if successful.
    
    def destroy
      response = API.instance.send_request('docs.delete', :doc_id => self.id)
      return response.elements['/rsp'].attributes['stat'] == 'ok'
    end
    
    # Returns the +doc_id+ attribute.
    
    def id
      self.doc_id
    end
    
    # Ensures that the +owner+ attribute cannot be set once the document is
    # saved.
    
    def owner=(newuser) #:nodoc:
      saved? ? raise(NotImplementedError, "Cannot change a document's owner once the document has been saved") : super
    end
    
    # Retrieves a document's download URL. You can provide a format for the
    # download. Valid formats are listed at
    # http://www.scribd.com/publisher/api?method_name=docs.getDownloadUrl
    #
    # If you do not provide a format, the link will be for the document's
    # original format.
    
    def download_url(format='original')
      @download_urls[format] ||= begin
        response = API.instance.send_request('docs.getDownloadUrl', :doc_id => self.id, :doc_type => format)
        response.elements['/rsp/download_link'].cdatas.first.to_s
      end
    end
  end
end
