module Scribd  
  class Document < Resource
    def initialize(options={})
      super
      
      @download_urls = {}
    end
    
    def id; doc_id end
    
    class << self
      alias_method :upload, :create
    
      def update_all(docs, options)
        raise ArgumentError, "docs must be an array" unless docs.is_a? Array
        raise ArgumentError, "docs must consist of Scribd::Document objects" unless docs.all? { |doc| doc.is_a? Document }
        raise ArgumentError, "You can't modify one or more documents" if docs.any? { |doc| doc.owner.nil? }
        raise ArgumentError, "options must be a hash" unless options.is_a? Hash
      
        docs_by_user = docs.inject(Hash.new { |hash, key| hash[key] = [] }) { |hash, doc| hash[doc.owner] << doc; hash }
        docs_by_user.each { |user, doc_list| API.request 'docs.changeSettings', options.merge(:doc_ids => doc_list.map(&:id).join(','), :session_key => user.session_key) }
      end

    
      def find(options={})
        doc_id = options.is_a?(Integer) ? options : nil
        raise ArgumentError, "You must specify a query or document ID" unless doc_id || (options.is_a?(Hash) && options[:query])
      
        if doc_id
          Document.new :xml => API.request('docs.getSettings', :doc_id => doc_id).xpath('/rsp')
        else
          options.merge! :num_results => options[:limit], :num_start => options[:offset]
          build_collection API.request 'docs.search', options
        end
      end

      def featured(options = {})
        build_collection API.request 'docs.featured', options
      end

      def browse(options = {})
        build_collection API.request 'docs.browse', options
      end
    
      def thumbnail_url(id, options={})
        w, h = if (options[:width] || options[:height]) && options[:size]
          raise ArgumentError, "Cannot specify both width/height and size"
        
        elsif options[:width] && options[:height]
          [options[:width], options[:height]]
        
        elsif options[:size]
          raise ArgumentError, "Size option must be a two-element array" unless options[:size].is_a?(Array) && options[:size].size == 2
          options[:size]
        
        elsif options[:width] || options[:height]
          raise ArgumentError, "Must specify both width and height, or neither"
        
        end
      
        API.request('thumbnail.get', { :doc_id => id, :width => w, :height => h, :page => options[:page] }.compact!).xpath('/rsp/thumbnail_url').text
      end
    end
    
    def save
      raise "'file' attribute must be specified for new documents" if !created? && !file
      raise PrivilegeError, "The current API user is not the owner of this document" if created? && file && (!owner || !owner.session_key)

      process_file! && process_thumb!
      
      @saved = true
    end
    
    def process_file!
      fields = @attributes.dup      
      fields.delete_keys :thumbnail, :file
      
      fields[:session_key] = fields.delete(:owner).session_key if owner
      
      if file
        fields[:doc_type] = fields.delete(:type)
        fields[:doc_type].downcase! if fields[:doc_type]
        fields[:rev_id] = fields.delete :doc_id

        response = if file =~ /^(http|https|ftp):\/\/.*$/i          
          API.request 'docs.uploadFromUrl', fields.merge!(:url => file)
        else
          API.request 'docs.upload', fields.merge!(:file => (file.is_a?(File) ? file.path : file))
        end
      
        if response
          load_attributes response.at_xpath('/rsp')
          @created = true
        end
      end
    end
    
    def process_thumb!
      fields = @attributes.dup
      
      if thumbnail
        file_path = if thumbnail =~ /^(http|https|ftp):\/\/.*$/i
          file = Tempfile.new 'thumb'
          file.binmode
          
          open(thumbnail) { |data| file.write data.read }          
          file.path
        else
          thumbnail.is_a?(File) ? thumbnail.path : thumbnail
        end

        API.request 'docs.uploadThumb', :file => file_path, :doc_id => id
      end
      
      fields[:session_key] = fields[:owner].session_key if fields[:owner]
      fields[:doc_ids] = id
      
      fields.delete :access if fields[:file]
      
      API.request 'docs.changeSettings', fields.delete_keys(:file, :type, :conversion_status, :owner, :thumbnail)
      
      fields[:owner] ||= API.user

      @attributes.update(fields)
    end
    
    def conversion_status
      API.request('docs.getConversionStatus', :doc_id => id).xpath('/rsp/conversion_status').text
    end

    def reads(options = {})
      @reads = API.request('docs.getStats', :doc_id => id).xpath('/rsp/reads').text if !@reads || options[:force]
      @reads
    end

    def destroy
      begin
        API.request('docs.delete', :doc_id => id).at_xpath('/rsp')['stat'] == 'ok'
      rescue ResponseError
        false
      end
    end
    
    def grant_access(user_identifier)
      Security.grant_access user_identifier, self
    end
    
    def revoke_access(user_identifier)
      Security.revoke_access user_identifier, self
    end
    
    def access_list
      Security.document_access_list(self)
    end
    
    def thumbnail_url(options={})
      Document.thumbnail_url id, options
    end
    
    def download_url(format='original')
      @download_urls[format] ||= API.request('docs.getDownloadUrl', :doc_id => id, :doc_type => format).xpath('/rsp/download_link').text
    end
  end
end
