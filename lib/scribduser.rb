module Scribd
  
  # A user of the Scribd website. API programs can use this class to log in as a
  # Scribd user, create new user accounts, and get information about the current
  # user.
  #
  # An API program begins by logging into Scribd:
  #
  #  user = Scribd::User.login 'login', 'pass'
  #
  # You can now access information about this user through direct method calls:
  #
  #  user.name #=> 'Real Name'
  #
  # If, at any time, you would like to retrieve the Scribd::User instance for
  # the currently logged-in user, simply call:
  #
  #  user = Scribd::API.instance.user
  #
  # For information on a user's attributes, please consult the online API
  # documentation at http://www.scribd.com/publisher/api?method_name=user.login
  #
  # You can create a new account with the signup (a.k.a. create) method:
  #
  #  user = Scribd::User.signup :username => 'testuser', :password => 'testpassword', :email => your@email.com
  
  class User < Resource
    
    # Creates a new, unsaved user with the given attributes. You can eventually
    # use this record to create a new Scribd account.
    
    def initialize(options={})
      super
      if options[:xml] then
        load_attributes(options[:xml])
        @saved = true
        @created = true
      else
        @attributes = options
      end
    end
    
    # For new, unsaved records, creates a new Scribd user with the provided
    # attributes, then logs in as that user. Currently modification of existing
    # Scribd users is not supported. Throws a ResponseError if a remote error
    # occurs.
    
    def save
      if not created? then
        response = API.instance.send_request('user.signup', @attributes)
        xml = response.get_elements('/rsp')[0]
        load_attributes(xml)
        API.instance.user = self
      else
        raise NotImplementedError, "Cannot update a user once that user's been saved"
      end
    end
    
    # Returns a list of all documents owned by this user. This list is _not_
    # backed by the server, so if you add or remove items from it, it will not
    # make those changes server-side. This also has some tricky consequences
    # when modifying a list of documents while iterating over it:
    #
    #  docs = user.documents
    #  docs.each(&:destroy)
    #  docs #=> Still populated, because it hasn't been updated
    #  docs = user.documents #=> Now it's empty
    #
    # Scribd::Document instances returned through this method have more
    # attributes than those returned by the Scribd::Document.find method. The
    # additional attributes are documented online at
    # http://www.scribd.com/publisher/api?method_name=docs.getSettings
    
    def documents
      response = API.instance.send_request('docs.getList', { :session_key => @attributes[:session_key] })
      documents = Array.new
      response.elements['/rsp/resultset'].elements.each do |doc|
        documents << Document.new(:xml => doc, :owner => self)
      end
      return documents
    end
    
    # Finds documents owned by this user matching a given query. The parameters
    # provided to this method are identical to those provided to
    # Scribd::Document.find.
    
    def find_documents(options)
      return nil unless @attributes[:session_key]
      Document.find options.merge(:scope => 'user', :session_key => @attributes[:session_key])
    end
    
    # Loads a Scribd::Document by ID. You can only load such documents if they 
    # belong to this user.
    
    def find_document(document_id)
      return nil unless @attributes[:session_key]
      response = API.instance.send_request('docs.getSettings', { :doc_id => document_id, :session_key => @attributes[:session_key] })
      Document.new :xml => response.elements['/rsp'], :owner => self
    end
    
    # Uploads a document to a user's document list. This method takes the
    # following options:
    #
    # +file+:: The location of a file on disk or the URL to a file on the Web
    # +type+:: The file's type (e.g., "txt" or "ppt"). Optional if the file has
    #          an extension (like "file.txt").
    #
    # There are other options you can specify. For more information, see the
    # Scribd::Document.save method.
    
    def upload(options)
      raise NotReadyError, "User hasn't been created yet" unless created?
      Document.create options.merge(:owner => self)
    end
    
    class << self
      alias_method :signup, :create
    end
    
    # Logs into Scribd using the given username and password. This user will be
    # used for all subsequent Scribd API calls. You must log in before you can
    # use protected API functions. Returns the Scribd::User instance for the
    # logged in user.
    
    def self.login(username, password)
      response = API.instance.send_request('user.login', { :username => username, :password => password })
      xml = response.get_elements('/rsp')[0]
      user = User.new(:xml => xml)
      API.instance.user = user
      return user
    end
    
    # Returns the +user_id+ attribute.
    
    def id
      self.user_id
    end
    
    def to_s #:nodoc:
      @attributes[:username]
    end
  end
end
