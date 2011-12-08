module Scribd
  class NotReadyError < StandardError; end    
  
  class MalformedResponseError < StandardError; end
  
  class PrivilegeError < StandardError; end
  
  class ResponseError < RuntimeError
    attr_reader :code
    
    def initialize(code)
      @code = code
    end
  end
end