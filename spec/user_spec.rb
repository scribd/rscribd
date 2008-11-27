old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Scribd::User do
  describe "initialized from attributes" do
    before :each do
      @user = Scribd::User.new(:username => 'sancho', :name => 'Sancho Sample')
    end
    
    it "should have its attributes set appropriately" do
      @user.username.should eql('sancho')
      @user.name.should eql('Sancho Sample')
    end
    
    it "should be unsaved" do
      @user.should_not be_saved
    end
    
    it "should be uncreated" do
      @user.should_not be_created
    end
  end
  
  describe "initialized from XML" do
    before :each do
      @user = Scribd::User.new(:xml => REXML::Document.new("<rsp stat='ok'><username>sancho</username><name>Sancho Sample</name></rsp>").root)
    end
    
    it "should have its attributes set appropriately" do
      @user.username.should eql('sancho')
      @user.name.should eql('Sancho Sample')
    end
    
    it "should be saved" do
      @user.should be_saved
    end
    
    it "should be created" do
      @user.should be_created
    end
  end
  
  describe "existing user" do
    before :each do
      @user = Scribd::User.new(:xml => REXML::Document.new("<rsp stat='ok'><user_id type='integer'>225</user_id><username>sancho</username><name>Sancho Sample</name><session_key>some key</session_key></rsp>").root)
    end
    
    it "should return the user_id for the id method" do
      @user.id.should eql(225)
    end
    
    it "should return the username for the to_s method" do
      @user.to_s.should eql(@user.username)
    end
    
    it "should not be saveable" do
      lambda { @user.save }.should raise_error(NotImplementedError)
    end
    
    describe "documents method" do
      before :each do
        @xml = REXML::Document.new("<rsp stat='ok'><resultset><result><doc_id type='integer'>123</doc_id></result><result><doc_id type='integer'>234</doc_id></result></resultset></rsp>")
      end
      
      it "should docs.getList with the session key" do
        Scribd::API.instance.should_receive(:send_request).once.with('docs.getList', { :session_key => 'some key' }).and_return(@xml)
        @user.documents
      end
      
      it "should return an array of received documents with the owner of each set to this user" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        docs = @user.documents
        docs.should be_kind_of(Array)
        docs.should have(2).items
        docs.first.id.should eql(123)
        docs.last.id.should eql(234)
        docs.each do |doc|
          doc.should be_kind_of(Scribd::Document)
          doc.owner.should eql(@user)
        end
      end
    end
    
    describe "find_documents method" do
      it "should call Document.find with an appropriate scope and session key" do
        Scribd::Document.should_receive(:find).once.with(hash_including(:scope => 'user', :session_key => 'some key'))
        @user.find_documents(:query => 'hi!')
      end
      
      it "should pass all options to the Document.find method" do
        Scribd::Document.should_receive(:find).once.with(hash_including(:foo => 'bar'))
        @user.find_documents(:foo => 'bar')
      end
    end
    
    describe "find_document method" do
      before :each do
        @xml = REXML::Document.new("<rsp stat='ok'><doc_id type='integer'>123</doc_id></rsp>")
      end
      
      it "should call docs.getSettings with the appropriate doc_id and session key" do
        Scribd::API.instance.should_receive(:send_request).once.with('docs.getSettings', { :doc_id => 123, :session_key => 'some key' }).and_return(@xml)
        @user.find_document(123)
      end
      
      it "should return an appropriate Document with the owner set" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        doc = @user.find_document(123)
        doc.should be_kind_of(Scribd::Document)
        doc.id.should eql(123)
        doc.owner.should eql(@user)
      end
    end
    
    it "should have an upoad method that calls Document.create" do
      Scribd::Document.should_receive(:create).once.with(:file => 'test', :owner => @user)
      @user.upload(:file => 'test')
    end
  end
  
  describe "new user" do
    before :each do
      @user = Scribd::User.new(:login => 'sancho', :name => 'Sancho Sample')
      @xml = REXML::Document.new("<rsp stat='ok'><newattr>newval</newattr></rsp>")
    end
    
    describe "save method" do
      it "should call user.signup with the user's attributes" do
        Scribd::API.instance.should_receive(:send_request).once.with('user.signup', { :login => 'sancho', :name => 'Sancho Sample' }).and_return(@xml)
        @user.save
      end
      
      it "should set any new attributes in the response" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        @user.save
        @user.newattr.should eql('newval')
      end
      
      it "should set the API user to this user" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        @user.save
        Scribd::API.instance.user.should eql(@user)
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
  
  describe ".username" do
    before :each do
      @xml = REXML::Document.new("<rsp stat='ok'><username>sancho</username><name>Sancho Sample</name></rsp>")
    end
    
    it "should call user.username with the username and password" do
      Scribd::API.instance.should_receive(:send_request).once.with('user.login', { :username => 'user', :password => 'pass' }).and_return(@xml)
      Scribd::User.login 'user', 'pass'
    end
    
    it "should create a new user from the resulting XML" do
      Scribd::API.instance.stub!(:send_request).and_return(@xml)
      user = Scribd::User.login('user', 'pass')
      user.username.should eql('sancho')
      user.name.should eql('Sancho Sample')
    end
    
    it "should set the API user" do
      Scribd::API.instance.stub!(:send_request).and_return(@xml)
      user = Scribd::User.login('user', 'pass')
      Scribd::API.instance.user.should eql(user)
    end
  end
end

Dir.chdir old_dir
