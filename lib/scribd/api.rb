module Scribd
  module API
    class << self
      attr_accessor :key, :secret, :user
    
      def request(request_method, fields = {})
        raise NotReadyError unless API.key and API.secret
        
        Request.new(request_method, fields).response
      end
    
      def reload
        self.key, self.secret, self.user = ENV['SCRIBD_API_KEY'], ENV['SCRIBD_API_SECRET'], Scribd::User.new
        self
      end
    end
  end
end