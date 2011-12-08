module Scribd  
  class User < Resource
    class << self
      alias_method :signup, :create
      
      def login(username, password)
        API.user = User.new :xml => API.request('user.login', { :username => username, :password => password }).at_xpath('/rsp')
      end
    end
    
    def save
      raise NotImplementedError, "Cannot update a user once that user's been saved" if created?
      
      load_attributes API.request('user.signup', @attributes).at_xpath('/rsp')
      API.user = self
    end
    
    def documents(options = {})
      Document.build_collection API.request('docs.getList', options.merge(:session_key => session_key)), :owner => self
    end
    
    def find_documents(options={})
      return unless session_key
      
      Document.find options.merge(:scope => 'user', :session_key => session_key)
    end
    
    def find_document(document_id)
      return unless session_key
      
      Document.new :xml => API.request('docs.getSettings', :doc_id => document_id, :session_key => session_key).xpath('/rsp'), :owner => self
    end
    
    def upload(options)
      raise NotReadyError, "User hasn't been created yet" unless created?
      
      Document.create options.merge(:owner => self)
    end
    
    def collections(options={})
      raise NotReadyError, "User hasn't been created yet" unless created?
      
      Collection.build_collection API.request('docs.getCollections', options.merge(:session_key => session_key)), :owner => self
    end
    
    def auto_sign_in_url(next_url="")
      raise NotReadyError, "User hasn't been created yet" unless created?
      
      API.request('user.getAutoSignInUrl', :session_key => session_key, :next_url => next_url).at_xpath('/rsp/url').text
    end
    
    def id; user_id end
    def to_s; username end
  end
end
