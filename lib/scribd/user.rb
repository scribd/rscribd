module Scribd
  
  # A user of the Scribd website. API programs can use this class to log in as a
  # Scribd user, create new user accounts, and get information about the current
  # user.
  #
  # An API program begins by logging into Scribd:
  #
  # <pre><code>user = Scribd::User.login 'login', 'pass'</code></pre>
  #
  # You can now access information about this user through direct method calls:
  #
  # <pre><code>user.name #=> 'Real Name'</code></pre>
  #
  # If, at any time, you would like to retrieve the {User} instance for the
  # currently logged-in user, simply call:
  #
  # <pre><code>user = Scribd::API.instance.user</code></pre>
  #
  # For information on a user's attributes, please consult the online API
  # documentation.
  #
  # You can create a new account with the {.signup} (a.k.a. {.create}) method:
  #
  # <pre><code>user = Scribd::User.signup :username => 'testuser', :password => 'testpassword', :email => your@email.com</code></pre>
  
  class User < Resource
    
    # Creates a new, unsaved user with the given attributes. You can eventually
    # use this record to create a new Scribd account.
    #
    # @param [Hash] options The initial attributes for the user.
    
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
    # Scribd users is not supported.
    #
    # @raise [Scribd::ResponseError] If a remote error occurs.
    
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
    
    # Returns a list of documents owned by this user. By default, the size of
    # the returned list is capped at 1,000. Use the @:limit@ and @:offset@
    # parameters to page through this user's documents; however, @:limit@ cannot
    # be greater than 1,000. This list is _not_ backed by the server, so if you
    # add or remove items from it, it will not make those changes server-side.
    # This also has some tricky consequences when modifying a list of documents
    # while iterating over it:
    #
    # <pre><code>
    # docs = user.documents
    # docs.each(&:destroy)
    # docs #=> Still populated, because it hasn't been updated
    # docs = user.documents #=> Now it's empty
    # </code></pre>
    #
    # {Scribd::Document} instances returned through this method have more
    # attributes than those returned by the {Scribd::Document.find} method. The
    # additional attributes are documented online.
    #
    # @param [Hash] options Options to provide to the API find method.
    # @return [Array<Scribd::Document>] The found documents.
    # @see #find_documents
    
    def documents(options = {})
      response = API.instance.send_request('docs.getList', options.merge(:session_key => @attributes[:session_key]))
      documents = Array.new
      response.elements['/rsp/resultset'].elements.each do |doc|
        documents << Document.new(:xml => doc, :owner => self)
      end
      return documents
    end
    
    # Finds documents owned by this user matching a given query. The parameters
    # provided to this method are identical to those provided to {.find}.
    #
    # @param [Hash] options Options to pass to the API find method.
    # @see #documents

    def find_documents(options={})
      return nil unless @attributes[:session_key]
      Document.find options.merge(:scope => 'user', :session_key => @attributes[:session_key])
    end
    
    # Loads a {Document} by ID. You can only load such documents if they belong
    # to this user.
    #
    # @param [Fixnum] document_id The Scribd document ID.
    # @return [Scribd::Document] The found document.
    # @return [nil] If nothing was found.
    
    def find_document(document_id)
      return nil unless @attributes[:session_key]
      response = API.instance.send_request('docs.getSettings', { :doc_id => document_id, :session_key => @attributes[:session_key] })
      Document.new :xml => response.elements['/rsp'], :owner => self
    end
    
    # Uploads a document to a user's document list. See the
    # {Scribd::Document#save} method for more information on the options hash.
    #
    # @param [Hash] options Options to pass to the API upload method.
    # @raise [Scribd::NotReadyError] If the user is unsaved.
    
    def upload(options)
      raise NotReadyError, "User hasn't been created yet" unless created?
      Document.create options.merge(:owner => self)
    end
    
    # Returns the collections this user has created. For information about
    # search options, see the online API documentation. The list of collections
    # is not memoized or cached locally.
    #
    # @param [Hash] options Options to pass to the API collections search
    # method.
    # @return [Array<Scribd::Collection>] The collections created by this user.
    # @raise [Scribd::NotReadyError] If the user is unsaved
    
    def collections(options={})
      raise NotReadyError, "User hasn't been created yet" unless created?
      response = API.instance.send_request('docs.getCollections', options.merge(:session_key => @attributes[:session_key]))
      collections = Array.new
      response.elements['/rsp/resultset'].elements.each do |coll|
        collections << Collection.new(:xml => coll, :owner => self)
      end
      return collections
    end
    
    # Returns a URL that, when visited, will automatically sign in this user and
    # then redirect to the provided URL.
    #
    # @param [String] next_url The URL to redirect to after signing in. By
    # default the user is redirected to the home page.
    # @return [String] An auto-sign-in URL.
    # @raise [Scribd::NotReadyError] If the receiver is not an existing user.
    
    def auto_sign_in_url(next_url="")
      raise NotReadyError, "User hasn't been created yet" unless created?
      response = API.instance.send_request('user.getAutoSignInUrl', :session_key => @attributes[:session_key], :next_url => next_url)
      return response.get_elements('/rsp/url').first.cdatas.first.to_s
    end
    
    class << self
      alias_method :signup, :create
    end
    
    # Logs into Scribd using the given username and password. This user will be
    # used for all subsequent Scribd API calls. You must log in before you can
    # use protected API functions.
    #
    # @param [String] username The Scribd user's login.
    # @param [String] password The Scribd user's password.
    # @return [Scribd::User] The logged-in user.
    
    def self.login(username, password)
      response = API.instance.send_request('user.login', { :username => username, :password => password })
      xml = response.get_elements('/rsp').first
      user = User.new(:xml => xml)
      API.instance.user = user
      return user
    end
    
    # @return [String] The @user_id@ attribute.
    
    def id
      self.user_id
    end

    # @private
    def to_s
      @attributes[:username]
    end
  end
end
