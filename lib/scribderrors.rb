module Scribd
  
  # Raised when API calls are made before a key and secret are specified.
  
  class NotReadyError < StandardError; end
    
  # Raised when the XML returned by Scribd is malformed.
  
  class MalformedResponseError < StandardError; end
  
  # Raised when trying to perform an action that isn't allowed for the current
  # active user. Note that this exception is thrown only if the error originates
  # locally. If the request must go out to the Scribd server before the
  # privilege error occurs, a Scribd::ResponseError will be thrown. Unless a
  # method's documentation indicates otherwise, assume that the error will
  # originate remotely and a Scribd::ResponseError will be thrown.
  
  class PrivilegeError < StandardError; end
  
  # Raised when a remote error occurs. Remote errors are referenced by numerical
  # code. The online API documentation has a list of possible error codes and
  # their descriptions for each API method.
  
  class ResponseError < RuntimeError
    # The error code.
    attr_reader :code
    
    # Initializes the error with a given code.
    
    def initialize(code)
      @code = code
    end
  end
end
