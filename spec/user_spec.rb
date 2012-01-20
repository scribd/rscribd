require 'spec_helper'

describe Scribd::User do
  before do
    Scribd::API.key = "test key"
    Scribd::API.secret = "secret"
  end
  
  let(:user) { Scribd::User.new(:xml => Nokogiri::XML("<rsp stat='ok'><user_id type='integer'>225</user_id><username>sancho</username><name>Sancho Sample</name><session_key>some key</session_key></rsp>").root) }
  
  describe "initialized from attributes" do
    subject { Scribd::User.new(:username => 'sancho', :name => 'Sancho Sample') }
    
    it { should_not be_saved }
    it { should_not be_created }
    
    its(:username) { should == 'sancho' }
    its(:name) { should == 'Sancho Sample' }
  end
  
  describe "initialized from XML" do
    subject { user }
    
    it { should be_saved }
    it { should be_created }
    
    its(:username) { should == 'sancho' }
    its(:name) { should == 'Sancho Sample' }
    its(:id) { should == 225 }
    its(:to_s) { should == 'sancho' }
  end
  
  describe "#save" do
    it { expect { user.save }.to raise_error(NotImplementedError) }
  end
    
  describe "#documents" do
    let(:xml) { "<rsp stat='ok'><resultset><result><doc_id type='integer'>123</doc_id></result><result><doc_id type='integer'>234</doc_id></result></resultset></rsp>" }
    
    context "without options" do
      subject { user.documents }
      
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "method=docs.getList&api_key=test%20key&api_sig=72f496fa692a4d4b5090caf745b2a111").
           to_return(:body => xml)
      end
      
      it { should be_kind_of(Array) }
      it { should have(2).items }
      
      its("first") { should be_kind_of Scribd::Document }
      its("first.id") { should == 123 }
      its("first.owner") { should == user }
      
      its("last") { should be_kind_of Scribd::Document }
      its("last.id") { should == 234 }
      its("last.owner") { should == user }
    end
    
    context "with an offset" do
      subject { user.documents(:offset => 1) }
      
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "offset=1&method=docs.getList&api_key=test%20key&api_sig=f95806581efa936d5a20dae819e1c801").
           to_return(:body => xml)
      end
      
      it { should be_kind_of Array }
    end
    
    context "with a limit" do
      subject { user.documents(:limit => 1) }
      
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "limit=1&method=docs.getList&api_key=test%20key&api_sig=19572674aecef045a86c298720d46ca3").
           to_return(:body => xml)
      end
      
      it { should be_kind_of Array }
    end
  end
    
  describe "#collections" do
    let(:response) { %q{<?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
          <resultset list="true">
            <result>
              <collection_id>61</collection_id>
              <collection_name>My Collection</collection_name>
              <doc_count>5</doc_count>
            </result>
            <result>
              <collection_id>62</collection_id>
              <collection_name>My Other Collection</collection_name>
              <doc_count>1</doc_count>
            </result>
          </resultset>
        </rsp>
    } }
    
    context "when the user is new" do
      it { expect { Scribd::User.new.collections }.should raise_error(Scribd::NotReadyError) }
    end
    
    context "when the user is not new" do
      
      context "without options" do
        subject { user.collections }
        
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "method=docs.getCollections&api_key=test%20key&api_sig=b80374e875a4fbd073ef00aa31fe98c8").
             to_return(:body => response)
        end
        
        it { should be_kind_of(Array) }
        it { should have(2).collections }
        its("first") { should be_kind_of Scribd::Collection }
        its("first.collection_id") { should == "61" }
        its("first.collection_name") { should == "My Collection" }
        its("first.doc_count") { should == "5" }
        its("first.owner") { should == user }
        
        its("last") { should be_kind_of Scribd::Collection }
        its("last.collection_id") { should == "62" }
        its("last.collection_name") { should == "My Other Collection" }
        its("last.doc_count") { should == "1" }
        its("last.owner") { should == user }
      end
    end
    
    context "with options" do
      subject { user.collections(:other => 'option') }
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "other=option&method=docs.getCollections&api_key=test%20key&api_sig=6c4269b137d6f6dc3e42f98ddc319c61").
           to_return(:body => response)
      end
      
      it { should be_kind_of Array }
    end
  end
  
  describe "#find_document" do    
    before do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=docs.getSettings&api_key=test%20key&api_sig=e4e72e702eddf41aad250a38df576195").
         to_return(:body => "<rsp stat='ok'><doc_id type='integer'>123</doc_id></rsp>")
    end
    
    subject { user.find_document(123) }
    
    it { should be_kind_of(Scribd::Document) }
    its(:id) { should == 123 }
    its(:owner) { should == user }
  end
  
  describe "#find_documents" do
    it "should pass all options to the Document.find method" do
      Scribd::Document.should_receive(:find).once.with(hash_including(:foo => 'bar', :scope => 'user', :session_key => 'some key'))
      user.find_documents(:foo => 'bar')
    end
  end
  
  describe "#upload" do
    it "should have an upload method that calls Document.create" do
      Scribd::Document.should_receive(:create).once.with(:file => 'test', :owner => user)
      user.upload(:file => 'test')
    end
  end
    
  describe "new user" do
    before do
      @user = Scribd::User.new(:login => 'sancho', :name => 'Sancho Sample')
    end
    
    describe "save method" do
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "login=sancho&name=Sancho%20Sample&method=user.signup&api_key=test%20key&api_sig=61f9beeea4be3a263b0793d7df570393").
           to_return(:body => "<rsp stat='ok'><newattr>newval</newattr></rsp>")
      end
      
      subject { @user.save }
      
      it "should set any new attributes in the response" do
        subject.newattr.should eql('newval')
      end
      
      it "should set the API user to this user" do
        subject
        Scribd::API.user.should eql(@user)
      end
    end
    
    it "should return nil for find_documents" do
      @user.find_documents(:query => 'test').should be_nil
    end
    
    it "should return nil for find_document" do
      @user.find_document(123).should be_nil
    end
    
    it "should not allow calls to upload" do
      lambda { @user.upload(:file => 'test') }.should raise_error(Scribd::NotReadyError)
    end
  end
  
  describe "#auto_sign_in_url" do
    let(:response) { '<rsp><url><![CDATA[hello]]></url></rsp>' }
    let(:user) { Scribd::User.new(:xml => Nokogiri::XML("<rsp stat='ok'><user_id type='integer'>225</user_id><username>sancho</username><name>Sancho Sample</name><session_key>some key</session_key></rsp>").root) }
    
    context "when the user isn't saved" do
      subject { Scribd::User.new.auto_sign_in_url }
      it { expect { subject }.to raise_error(Scribd::NotReadyError) }
    end
    
    context "when the user is saved" do
      context "with next_url" do
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "next_url=foobar&method=user.getAutoSignInUrl&api_key=test%20key&api_sig=ff2b5d8b98b75538518d905677e5d986").
             to_return(:body => response)
        end
        subject { user.auto_sign_in_url('foobar') }
        it { should == "hello" }
      end
      
      context "without next_url" do
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "next_url=&method=user.getAutoSignInUrl&api_key=test%20key&api_sig=349f2e281cf1cc8febdda4693ddc4382").
             to_return(:body => response)
        end
        subject { user.auto_sign_in_url }
        it { should == "hello" }
      end
    end
  end
  
  describe ".login" do    
    before do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "username=user&password=pass&method=user.login&api_key=test%20key&api_sig=59ae4c057f37da654198a80eb2488c7a").
         to_return(:body => "<rsp stat='ok'><username>sancho</username><name>Sancho Sample</name></rsp>")
    end
    
    subject { Scribd::User.login 'user', 'pass' }
    
    its(:username) { should == "sancho" }
    its(:name) { should == "Sancho Sample" }

    it "should change the API user" do
      subject
      Scribd::API.user.should == subject
    end
  end
end