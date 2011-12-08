require 'spec_helper'

describe Scribd::Security do
  before do
    Scribd::API.key = "test key"
    Scribd::API.secret = "secret"
  end
  
  let(:document) { Scribd::Document.new(:xml => Nokogiri::XML('<result><doc_id>123</doc_id></result>').root) }
  
  describe ".grant_access" do
    it "should call set_access" do
      Scribd::Security.should_receive(:set_access).with('foo', true, document)
      Scribd::Security.grant_access 'foo', document
    end
  end
  
  describe ".revoke_access" do
    it "should call set_access" do
      Scribd::Security.should_receive(:set_access).with('foo', false, document)
      Scribd::Security.revoke_access 'foo', document
    end
  end
  
  describe ".set_access" do
    it "should make an API call to security.setAccess (nil document, access_allowed = 1)" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "user_identifier=foo&allowed=1&method=security.setAccess&api_key=test%20key&api_sig=56f2f9db151235c083b89517b24052d0").
         to_return(:body => "<rsp stat='ok' />")
         
      Scribd::Security.set_access 'foo', true
    end
    
    it "should set the doc_id when given a Scribd::Document" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "user_identifier=foo&allowed=1&doc_id=123&method=security.setAccess&api_key=test%20key&api_sig=5b298e86325169c38ecf9ff98eb71706").
         to_return(:body => "<rsp stat='ok' />")
      
      Scribd::Security.set_access 'foo', true, document
    end
    
    it "should set the doc_id when given a number" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "user_identifier=foo&allowed=1&doc_id=123&method=security.setAccess&api_key=test%20key&api_sig=5b298e86325169c38ecf9ff98eb71706").
         to_return(:body => "<rsp stat='ok' />")
               
      Scribd::Security.set_access 'foo', true, 123
    end
    
    context "when given anything else" do
      it { expect { Scribd::Security.set_access 'foo', true, Object.new }.to raise_error(ArgumentError) }
    end
    
    it "should set allowed to 0 when given false" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "user_identifier=foo&allowed=0&method=security.setAccess&api_key=test%20key&api_sig=5a5a53ef467363c5fdbb26a725450538").
         to_return(:body => "<rsp stat='ok' />")
               
      Scribd::Security.set_access 'foo', false
    end
  end
  
  describe ".document_access_list" do
    let(:ident_list) { <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <rsp stat="ok">
        <resultset list="true">
          <result>
            <user_identifier>leila83</user_identifier>
          </result>
          <result>
            <user_identifier>spikyhairdude</user_identifier>
          </result>
        </resultset>
      </rsp>
      EOF
    }
    
    it "should make an API call to security.getDocumentAccessList with the document ID" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=security.getDocumentAccessList&api_key=test%20key&api_sig=289e81213270a002c3dc9d7b490ac80f").
         to_return(:body => ident_list)
         
      Scribd::Security.document_access_list(document).should == %w(leila83 spikyhairdude)
    end
    
    it "should accept ID numbers" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=security.getDocumentAccessList&api_key=test%20key&api_sig=289e81213270a002c3dc9d7b490ac80f").
         to_return(:body => ident_list)
         
      Scribd::Security.document_access_list(123)
    end
  end
  
  describe '.user_access_list' do
    let(:doc_list) { <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <rsp stat="ok">
        <resultset list="true">
          <result>
            <doc_id>244565</doc_id>
            <title>&lt;![CDATA[Ruby on Java]]&gt;</title>
            <description>&lt;![CDATA[Ruby On Java, Barcamp, Washington DC]]&gt;</description>
            <access_key>key-t3q5qujoj525yun8gf7</access_key>
            <conversion_status>DONE</conversion_status>
            <page_count>10</page_count>
          </result>
          <result>
            <doc_id>244567</doc_id>
            <title>&lt;![CDATA[Ruby on Java Part II]]&gt;</title>
            <description>&lt;![CDATA[Ruby On Java Part II, Barcamp, Washington DC]]&gt;</description>
            <access_key>key-2b3udhalycthsm91d1ps</access_key>
            <conversion_status>DONE</conversion_status>
            <page_count>12</page_count>
          </result>
        </resultset>
      </rsp>
    EOF
    }
    
    before do 
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "user_identifier=123&method=security.getUserAccessList&api_key=test%20key&api_sig=32de287029361e9a700b11d9381d8777").
         to_return(:body => doc_list)
    end
    
    subject { Scribd::Security.user_access_list('123') }
    
    it { should be_kind_of Array }
    it { should have(2).items }
    its(:first) { should be_kind_of Scribd::Document }
    its(:last) { should be_kind_of Scribd::Document }
  end
end
