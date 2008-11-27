old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Scribd::API do
  it "should be a singleton" do
    Scribd::API.instance.should be_kind_of(Scribd::API)
    lambda { Scribd::API.new }.should raise_error(NoMethodError)
  end
  
  describe "with the API key and secret in ENV" do
    before :each do
      ENV['SCRIBD_API_KEY'] = 'env key'
      ENV['SCRIBD_API_SECRET'] = 'env sec'
      @api = Scribd::API.send(:new)
    end
    
    it "should set the API key and secret accordingly" do
      @api.key.should eql('env key')
      @api.secret.should eql('env sec')
    end
    
    it "should favor local API key and secret settings" do
      @api.key = 'test key'
      @api.secret = 'test sec'
      @api.key.should eql('test key')
      @api.secret.should eql('test sec')
    end
  end
  
  describe "freshly reset" do
    before :each do
      ENV['SCRIBD_API_KEY'] = nil
      ENV['SCRIBD_API_SECRET'] = nil
      # reset the singleton; total hack
      @api = Scribd::API.send(:new)
    end
    
    it "should raise NotReadyError when send_request is called" do
      lambda { @api.send_request('blah', {}) }.should raise_error(Scribd::NotReadyError)
    end
    
    describe "with a key and secret set" do
      before :each do
        @api.key = 'test key'
        @api.secret = 'test sec'
      end
      
      it "should have the correct API key and secret" do
        @api.key.should eql('test key')
        @api.secret.should eql('test sec')
      end
      
      it "should raise ArgumentError if the method is empty" do
        lambda { @api.send_request(nil, {}) }.should raise_error(ArgumentError)
        lambda { @api.send_request('', {}) }.should raise_error(ArgumentError)
      end
      
      describe "with a mocked Net::HTTP" do
        before :each do
          @response = mock('Net::HTTP::Response @response')
          @response.stub!(:body).and_return("<rsp stat='ok'/>")
          
          @http = Net::HTTP.new('http://www.example.com', 80)
          @http.stub!(:request).and_return(@response)
          Net::HTTP.stub!(:new).and_return(@http)
          
          @request = Net::HTTP::Post.new('/test')
          Net::HTTP::Post.stub!(:new).and_return(@request)
        end
        
        it "should set a nice, long read timeout" do
          @api.send_request('test', {})
          @http.read_timeout.should >= 60
        end
        
        it "should set the multipart parameters to the given fields" do
          fields = { :field1 => 1, :field2 => 'hi' }
          @api.send_request('test', fields)
          body = @request.body
          fields.each do |key, value|
            serial_str = <<-EOF
Content-Disposition: form-data; name=#{key.to_s.inspect}

#{value.to_s}
            EOF
            body.should include(serial_str.gsub(/\n/, "\r\n"))
          end
        end
        
        # it "should attempt to make the request 3 times" do
        #   @http.stub!(:request).and_raise Exception
        #   @http.should_receive(:request).exactly(3).times
        #   lambda { @api.send_request('test', {}) }.should raise_error
        # end
        
        it "should raise MalformedResponseError if the response doesn't have an rsp tag as its root" do
          @response.stub!(:body).and_return("<invalid/>")
          lambda { @api.send_request('test', {}) }.should raise_error(Scribd::MalformedResponseError)
        end
        
        it "should raise a ResponseError for error responses" do
          @response.stub!(:body).and_return("<rsp stat='fail'><error code='123' message='testmsg' /></rsp>")
          lambda { @api.send_request('testmeth', {}) }.should raise_error(Scribd::ResponseError) { |error|
            error.code.should eql("123")
            error.message.should eql('Method: testmeth Response: code=123 message=testmsg')
          }
        end
        
        it "should return the REXML doc for successful responses" do
          @response.stub!(:body).and_return("<rsp stat='ok'><element attr='val'><otherelem>val2</otherelem></element></rsp>")
          @api.send_request('testmeth', {}).should be_kind_of(REXML::Document)
        end
      end
    end
  end
  
  it "should not be asynchronous by default" do
    Scribd::API.instance.asynchronous.should_not be_true
  end
  
  it "should not be in debug mode by default" do
    Scribd::API.instance.instance_variable_get(:@debug).should_not be_true
  end
  
  it "should have no user by default" do
    Scribd::API.instance.user.should be_nil
  end
end

Dir.chdir old_dir
