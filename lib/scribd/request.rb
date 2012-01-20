module Scribd
  class Request
    attr_reader :params, :request_method
    
    TRIES = 3
    
    Connection = Curl::Easy.new("http://api.scribd.com/api")
    Connection.multipart_form_post = true
    Connection.timeout = 15 * 60
    
    def initialize(request_method, params = {})
      raise ArgumentError, "Method should be given" if !request_method || request_method.empty?
      
      @request_method, @params = request_method, params
    end
        
    def response
      perform && validate
      
      @response
    end
    
    protected
    def perform
      tries = TRIES
      
      begin
        tries -= 1
        
        Connection.http_post(*payload)
        @response = Nokogiri::XML Connection.body_str
        
      rescue Exception
        Kernel.sleep(20) && retry if tries > 0
        
        raise $!
      end
    end
    
    def payload
      parts, fields = [], self.fields
      parts << Curl::PostField.file('file', fields.delete('file')) if fields.has_key? 'file'

      parts + fields.map { |name, body| Curl::PostField.content(name, body.to_s) }
    end
    
    def fields
      fields = params.stringify_keys.merge 'method' => request_method, 'api_key' => API.key
      
      unless fields['session_key'] && fields['my_user_id']
        case API.user
        when Scribd::User
          fields['session_key'] = API.user.session_key
        when String
          fields['my_user_id'] = API.user
        end
      end
      
      fields.compact!
      fields.merge! 'api_sig' => sign(fields)
    end
    
    def sign(fields)
      sign_fields = fields.dup
      sign_fields.delete 'file'
      
      Digest::MD5.hexdigest(API.secret + sign_fields.sort.flatten.join).to_s
    end
    
    def validate
      raise MalformedResponseError, "The response received from the remote host could not be interpreted" unless @response.at_xpath('/rsp')
      
      if @response.at_xpath('/rsp')['stat'] == 'fail'
        error = @response.at_xpath('/rsp/error')
        code, message = error ? [error['code'], error['message']] : [-1, "Unidentified error:\n#{@response}"]
      
        raise ResponseError.new(code), "Method: #{@request_method} Response: code=#{code} message=#{message}"
      end
    end
  end
end