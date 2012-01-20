require 'spec_helper'

describe Scribd::API do
  describe "an instance" do
    subject { Scribd::API }
    
    it { should_not respond_to(:new) }
    its(:user) { should_not be_nil }
  end
  
  context "with the API key and secret in ENV" do
    before do
      ENV['SCRIBD_API_KEY'] = 'env key'
      ENV['SCRIBD_API_SECRET'] = 'env sec'
    end
    
    subject { Scribd::API.reload }
    
    its(:key) { should == 'env key' }
    its(:secret) { should == 'env sec' }
    
    context "but the API key and secret locally set" do
      before do
        subject.key = 'test key'
        subject.secret = 'test sec'
      end
      
      its(:key) { should == 'test key' }
      its(:secret) { should == 'test sec' }
    end
  end
  
  context "without the API key and secret in ENV" do
    before do
      ENV['SCRIBD_API_KEY'] = nil
      ENV['SCRIBD_API_SECRET'] = nil
    end
    
    subject { Scribd::API.reload }
    
    it { expect { subject.request 'blah' }.to raise_error(Scribd::NotReadyError) }
    
    context "with a key and secret locally set" do
      before { subject.key, subject.secret = 'test key', 'test sec' }
      
      its(:key) { should == 'test key' }
      its(:secret) { should == 'test sec' }
      
      it { expect { subject.request nil }.to raise_error(ArgumentError) }
      it { expect { subject.request '' }.to raise_error(ArgumentError) }
    end
  end
  
  describe "#request" do
    before do
      @api = Scribd::API
      @api.key, @api.secret = 'test key', 'test sec'
    end
    
    context "when the request has parameters" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "field1=1&field2=hi&method=test&api_key=test%20key&api_sig=cd1a695a72a9f090e47af0f3272f970c")
          .to_return(:body => "<rsp stat='ok' />")
      end
      
      subject { @api.request('test', { :field1 => 1, :field2 => 'hi' }) }
      
      it { should be_kind_of Nokogiri::XML::Document }
    end
    
    context "when the response doesn't have an rsp tag as its root" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "method=test&api_key=test%20key&api_sig=eb4a6e58e8cae5d4ac7eee812e4108fc")
          .to_return(:body => "<invalid/>")
      end
      
      subject { @api.request('test') }
      
      it { expect { subject }.to raise_error(Scribd::MalformedResponseError) }
    end
    
    context "when the response is an error response" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "method=testmeth&api_key=test%20key&api_sig=35568d601d61bbcc15816ae423bc7587")
          .to_return(:body => "<rsp stat='fail'><error code='123' message='testmsg' /></rsp>")
      end
      
      subject { @api.request('testmeth') }
      
      it { expect { subject }.to raise_error(Scribd::ResponseError) { |error|
        error.code.should == "123"
        error.message.should == 'Method: testmeth Response: code=123 message=testmsg'
      } }
    end
    
    context "when an exception occurs" do      
      subject { @api.request('test') }
      
      it "should retry 3 times" do
        Scribd::Request::Connection.should_receive(:http_post).exactly(3).times.and_raise(Exception)
        Kernel.should_receive(:sleep).with(20).exactly(2).times.and_return(true)
        expect { subject }.to raise_error(Exception)
      end
    end
    
    context "when using a my_user_id" do
      before do
        Scribd::API.user = "my_user_id"
        
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "method=test&api_key=test%20key&my_user_id=my_user_id&api_sig=42320d29adcdd8a240729ec6e5363c41").
           to_return(:body => "<rsp stat='ok' />")
      end
      
      subject { @api.request('test') }
      
      it { should be_kind_of Nokogiri::XML::Document }
    end
  end
end
