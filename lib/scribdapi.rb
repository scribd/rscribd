require 'singleton'
require 'md5'
require 'rexml/document'

module Scribd
  
  # This class acts as the top-level interface between Scribd and your
  # application. Before you can begin using the Scribd API, you must specify for
  # this object your API key and API secret. They are available on your
  # Platform home page.
  #
  # This class is a singleton. Its only instance is accessed using the
  # +instance+ class method.
  #
  # To begin, first specify your API key and secret:
  #
  #  Scribd::API.instance.key = 'your API key here'
  #  Scribd::API.instance.secret = 'your API secret here'
  #
  # (If you set the +SCRIBD_API_KEY+ and +SCRIBD_API_SECRET+ Ruby environment
  # variables before loading the gem, these values will be set automatically for
  # you.)
  #
  # Next, you should log in to Scribd, or create a new account through the gem.
  #
  #  user = Scribd::User.login 'login', 'password'
  #
  # You are now free to use the Scribd::User or Scribd::Document classes to work
  # with Scribd documents or your user account.
  #
  # If you need the Scribd::User instance for the currently logged in user at a
  # later point in time, you can retrieve it using the +user+ attribute:
  #
  #  user = Scribd::API.instance.user
  #
  # In addition, you can save and restore sessions by simply storing this user
  # instance and assigning it to the API at a later time. For example, to
  # restore the session retrieved in the previous example:
  #
  #  Scribd::API.instance.user = user
  #
  # In addition to working with Scribd users, you can also work with your own
  # website's user accounts. To do this, set the Scribd API user to a string
  # containing a unique identifier for that user (perhaps a login name or a user
  # ID):
  #
  #  Scribd::API.instance.user = my_user_object.mangled_user_id
  #
  # A "phantom" Scribd user will be set up with that ID, so you any documents
  # you upload will be associated with that account.
  #
  # For more hints on what you can do with the Scribd API, please see the
  # Scribd::Document class.
  
  class API
    include Singleton
    
    HOST = 'api.scribd.com' #:nodoc:
    PORT = 80 #:nodoc:
    REQUEST_PATH = '/api' #:nodoc:
    TRIES = 3 #:nodoc:
    
    attr_accessor :key # The API key you were given when you created a Platform account.
    attr_accessor :secret # The API secret used to validate your key (also provided with your account).
    attr_accessor :user # The currently logged in user.
    attr_accessor :asynchronous # If true, requests are processed asynchronously. If false, requests are blocking.
    attr_accessor :debug # If true, extended debugging information is printed
    
    def initialize #:nodoc:
      @asychronous = false
      @key = ENV['SCRIBD_API_KEY']
      @secret = ENV['SCRIBD_API_SECRET']
    end
    
    def send_request(method, fields={}) #:nodoc:
      raise NotReadyError unless @key and @secret
      # See if method is given
      raise ArgumentError, "Method should be given" if method.nil? || method.empty?
      
      debug("** Remote method call: #{method}; fields: #{fields.inspect}")
      
      # replace pesky hashes to prevent accidents
      fields = fields.stringify_keys

      # Complete fields with the method name
      fields['method'] = method
      fields['api_key'] = @key
      
      if fields['session_key'].nil? and fields['my_user_id'].nil? then
        if @user.kind_of? Scribd::User then
          fields['session_key'] = @user.session_key
        elsif @user.kind_of? String then
          fields['my_user_id'] = @user
        end
      end
      
      fields.reject! { |k, v| v.nil? }

      # Don't include file in parameters to calculate signature
      sign_fields = fields.dup
      sign_fields.delete 'file'

      fields['api_sig'] = sign(sign_fields)
      debug("** POST parameters: #{fields.inspect}")

      # Create the connection
      http = Net::HTTP.new(HOST, PORT)
      # TODO configure timeouts through the properties

      # API methods can be SLOW.  Make sure this is set to something big to prevent spurious timeouts
      http.read_timeout = 15*60

      request = Net::HTTP::Post.new(REQUEST_PATH)
      request.multipart_params = fields

      tries = TRIES
      begin
        tries -= 1
        res = http.request(request)
      rescue Exception
        $stderr.puts "Request encountered error, will retry #{tries} more."
        if tries > 0
          # Retrying several times with sleeps is recommended.
          # This will prevent temporary downtimes at Scribd from breaking API applications
          sleep(20)
          retry
        end
        raise $!
      end
      
      debug "** Response:"
      debug(res.body)
      debug "** End response"

      # Convert response into XML
      xml = REXML::Document.new(res.body)
      raise MalformedResponseError, "The response received from the remote host could not be interpreted" unless xml.elements['/rsp']

      # See if there was an error and raise an exception
      if xml.elements['/rsp'].attributes['stat'] == 'fail'
        # Load default code and error
        code, message = -1, "Unidentified error:\n#{res.body}"

        # Get actual error code and message
        err = xml.elements['/rsp/error']
        code, message = err.attributes['code'], err.attributes['message'] if err

        # Add more data
        message = "Method: #{method} Response: code=#{code} message=#{message}"

        raise ResponseError.new(code), message
      end

      return xml
    end

    private 

    # FIXME: Since we don't need XMLRPC, the exception could be different
    # TODO: It would probably be better if we wrapped the fault
    # in something more meaningful. At the very least, a broad
    # division of errors, such as retryable and fatal. 
    def error(el) #:nodoc:
      att = el.attributes
      fe = XMLRPC::FaultException.new(att['code'].to_i, att['msg'])
      $stderr.puts "ERR: #{fe.faultString} (#{fe.faultCode})"
      raise fe
    end

    # Checks if a string parameter is given and not empty.
    # 
    # Parameters:
    #   name  - parameter name for an error message.
    #   value - value.
    #   
    # Raises:
    #   ArgumentError if the value is nil, or empty.
    #
    def check_not_empty(name, value) #:nodoc:
      check_given(name, value)
      raise ArgumentError, "#{name} must not be empty" if value.to_s.empty?
    end

    # Checks if the value is given.
    #
    # Parameters:
    #   name  - parameter name for an error message.
    #   value - value.
    #   
    # Raises:
    #   ArgumentError if the value is nil.
    #
    def check_given(name, value) #:nodoc:
      raise ArgumentError, "#{name} must be given" if value.nil?
    end
    
    # Sign the arguments hash with our very own signature.
    #
    # Parameters:
    #   args - method arguments to be sent to the server API
    # 
    # Returns:
    #   signature
    #
    def sign(args)
      return MD5.md5(@secret + args.sort.flatten.join).to_s
    end
    
    # Outputs whatever is given into the $stderr if debugging is enabled.
    #
    # Parameters:
    #   args - content to output
    def debug(str)
      $stderr.puts(str) if @debug
    end
  end
end
