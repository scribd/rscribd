old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Scribd::Document do
  before :each do
    Scribd::API.instance.key = 'test key'
    Scribd::API.instance.secret = 'test sec'
  end
  
  describe "initialized from attributes" do
    before :each do
      @document = Scribd::Document.new(:access => 'private', :title => 'mytitle')
    end
    
    it "should have its attributes set appropriately" do
      @document.access.should eql('private')
      @document.title.should eql('mytitle')
    end
    
    it "should be unsaved" do
      @document.should_not be_saved
    end
    
    it "should be uncreated" do
      @document.should_not be_created
    end
  end
  
  describe "initialized from XML" do
    before :each do
      @owner = mock('Scribd::User @owner')
      @document = Scribd::Document.new(:xml => REXML::Document.new("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root, :owner => @owner)
    end
    
    it "should have its attributes set appropriately" do
      @document.attr1.should eql('val1')
      @document.attr2.should eql('val2')
    end
    
    it "should be saved" do
      @document.should be_saved
    end
    
    it "should be created" do
      @document.should be_created
    end
    
    it "should have its owner set appropriately" do
      @document.owner.should eql(@owner)
    end
  end
  
  describe "not yet created" do
    before :each do
      @document = Scribd::Document.new(:access => 'private', :title => 'mytitle')
    end
    
    it "should raise an exception if saved without a file" do
      lambda { @document.save }.should raise_error
    end
  end
  
  describe "created" do
    before :each do
      @http = mock('Net::HTTP @http')
      @http.stub! :read_timeout=
      @response = mock('Net::HTTPResponse @response')
      @response.stub!(:body).and_return "<rsp stat='ok'></rsp>"
      @http.stub!(:request).and_return(@response)
      Net::HTTP.stub!(:new).and_return(@http)
    end
    
    it "should not raise an exception if saved" do
      @document = Scribd::Document.new(:xml => REXML::Document.new("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root)
      lambda { @document.save }.should_not raise_error
    end
    
    describe "that we own" do
      before :each do
        @owner = mock('Scribd::User @owner')
        @owner.stub!(:session_key).and_return('test session key')
        @document = Scribd::Document.new(:xml => REXML::Document.new("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root, :owner => @owner)
      end
    end
    
    describe "that we don't own" do
      before :each do
        @owner = mock('Scribd::User @owner')
        @owner.stub!(:session_key)
        @document = Scribd::Document.new(:xml => REXML::Document.new("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root, :owner => @owner)
      end
      
      it "should raise PrivilegeError when trying to change the file" do
        @document.file = 'sample/test.txt'
        lambda { @document.save }.should raise_error(Scribd::PrivilegeError)
      end
    end
    
    describe "with no owner" do
      before :each do
        @document = Scribd::Document.new(:xml => REXML::Document.new("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root)
      end
      
      it "should raise PrivilegeError when trying to change the file" do
        @document.file = 'sample/test.txt'
        lambda { @document.save }.should raise_error(Scribd::PrivilegeError)
      end
    end
  end
  
  describe "to be uploaded from file" do
    before :each do
      @document = Scribd::Document.new(:file => 'sample/test.txt')
    end
    
    it "should make a call to docs.upload" do
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:file => an_instance_of(File)))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
  end
  
  describe "to be uploaded from URL" do
    before :each do
      @document = Scribd::Document.new(:file => 'http://www.example.com/file.txt')
    end
    
    it "should make a call to docs.uploadFromUrl" do
      Scribd::API.instance.should_receive(:send_request).with('docs.uploadFromUrl', hash_including(:url => 'http://www.example.com/file.txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should recognize HTTPS URLs" do
      @document.file.gsub!(/http/, 'https')
      Scribd::API.instance.should_receive(:send_request).with('docs.uploadFromUrl', hash_including(:url => 'https://www.example.com/file.txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should recognize FTP URLs" do
      @document.file.gsub!(/http/, 'ftp')
      Scribd::API.instance.should_receive(:send_request).with('docs.uploadFromUrl', hash_including(:url => 'ftp://www.example.com/file.txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
  end
  
  describe "to be uploaded" do
    before :each do
      @document = Scribd::Document.new(:file => 'sample/test.txt')
    end
    
    describe "ignoring the changeSettings call" do
    end
    
    it "should set the doc_type attribute to the file's extension" do
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => 'txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should prefer a doc_type set in the type attribute" do
      @document.type = 'pdf'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => 'pdf'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should not raise an exception if the document does not have an extension" do
      @document.file = 'Rakefile'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => nil))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      lambda { @document.save }.should_not raise_error
    end
    
    it "should downcase filename extensions" do
      @document.file = 'sample/test.TXT'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => 'txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      lambda { @document.save }.should_not raise_error
    end
    
    it "should downcase attributed file extensions" do
      @document.type = 'PDF'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => 'pdf'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should set the rev_id field to the doc_id attribute" do
      @document.doc_id = 123
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:rev_id => 123))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should set the access field to the access attribute" do
      @document.access = 'private'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:access => 'private'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should set the session_key field to the owner's session key" do
      owner = mock('Scribd::User owner')
      owner.stub!(:session_key).and_return('his key')
      @document.owner = owner
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:session_key => 'his key'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    it "should pass through any other attributes to the docs.upload call" do
      @document.hello = 'there'
      Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:hello => 'there'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
    
    describe "successfully" do
      before :each do
        @document.stub!(:id).and_return(3)
        @xml = REXML::Document.new("<rsp stat='ok'><access_key>abc123</access_key></rsp>")
        Scribd::API.instance.should_receive(:send_request).with('docs.upload', an_instance_of(Hash)).and_return(@xml)
      end
      
      describe "without testing changeSettings" do
        before :each do
          Scribd::API.instance.should_receive(:send_request).with('docs.changeSettings', an_instance_of(Hash))
        end
        
        it "should load attributes from the response" do
          @document.save
          @document.access_key.should eql('abc123')
        end

        it "should set created to true" do
          @document.save
          @document.should be_created
        end
        
        it "should set saved to true" do
          @document.save
          @document.should be_saved
        end
        
        it "should return true" do
          @document.save.should be_true
        end
      end
      
      it "should not send the file, type, or access parameters to the changeSettings call" do
        @document.type = 'pdf'
        @document.access = 'private'
        Scribd::API.instance.should_not_receive(:send_request).with('docs.changeSettings', hash_including(:file => 'sample/text.txt'))
        Scribd::API.instance.should_not_receive(:send_request).with('docs.changeSettings', hash_including(:type => 'pdf'))
        Scribd::API.instance.should_not_receive(:send_request).with('docs.changeSettings', hash_including(:access => 'private'))
        @document.save
      end
      
      it "should pass all other attributes to the changeSettings call" do
        @document.attr1 = 'val1'
        Scribd::API.instance.should_receive(:send_request).with('docs.changeSettings', hash_including(:attr1 => 'val1'))
        @document.save
      end
      
      it "should pass the owner's session key to changeSettings" do
        owner = mock('Scribd::User owner')
        owner.stub!(:session_key).and_return('his key')
        @document.owner = owner
        Scribd::API.instance.should_receive(:send_request).with('docs.changeSettings', hash_including(:session_key => 'his key'))
        @document.save
      end
      
      it "should pass the document's ID to changeSettings" do
        Scribd::API.instance.should_receive(:send_request).with('docs.changeSettings', hash_including(:doc_ids => 3))
        @document.save
      end
    end
  end
  
  describe ".update_all" do
    before :each do
      @owner1 = mock('Scribd::User @owner1')
      @owner1.stub!(:session_key).and_return 'session1'
      @docs = [
        Scribd::Document.new(:owner => @owner1, :doc_id => 1),
        Scribd::Document.new(:owner => @owner1, :doc_id => 2)
      ]
    end
    
    it "should raise ArgumentError if an array of docs is not provided" do
      lambda { Scribd::Document.update_all 'string', {} }.should raise_error(ArgumentError)
    end
    
    it "should raise ArgumentError unless all array elements are Scribd::Documents" do
      @docs << 'string'
      lambda { Scribd::Document.update_all @docs, {} }.should raise_error(ArgumentError)
    end
    
    it "should raise ArgumentError unless all documents have session keys" do
      @docs << Scribd::Document.new
      lambda { Scribd::Document.update_all @docs, {} }.should raise_error(ArgumentError)
    end
    
    it "should raise ArgumentError unless options is a hash" do
      lambda { Scribd::Document.update_all @docs, 'string' }.should raise_error(ArgumentError)
    end
    
    it "should call changeSettings once for each session key" do
      @owner2 = mock('Scribd::User @owner2')
      @owner2.stub!(:session_key).and_return 'session2'
      @docs << Scribd::Document.new(:owner => @owner2, :doc_id => 3)
      Scribd::API.instance.should_receive(:send_request).once.with('docs.changeSettings', hash_including(:session_key => 'session1'))
      Scribd::API.instance.should_receive(:send_request).once.with('docs.changeSettings', hash_including(:session_key => 'session2'))
      Scribd::Document.update_all @docs, { :access => 'private' }
    end
    
    it "should set the doc_ids field to a comma-delimited list of document IDs" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.changeSettings', hash_including(:doc_ids => '1,2'))
      Scribd::Document.update_all @docs, { :access => 'private' }
    end
    
    it "should pass all options to the changeSettings call" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.changeSettings', hash_including(:access => 'private', :bogus => 'test'))
      Scribd::Document.update_all @docs, { :access => 'private', :bogus => 'test' }
    end
  end
  
  describe ".find" do
    it "should raise an ArgumentError if an invalid doc ID is provided" do
      lambda { Scribd::Document.find('oh hai') }.should raise_error(ArgumentError)
    end
    
    it "should raise an ArgumentError if a query is not provided for scoped lookups" do
      lambda { Scribd::Document.find(:all, :title => 'hi') }.should raise_error(ArgumentError)
    end
    
    describe "by ID" do
      before :each do
        @xml = REXML::Document.new("<rsp stat='ok'><access_key>abc123</access_key></rsp>")
      end
      
      it "should call getSettings with the doc ID" do
        Scribd::API.instance.should_receive(:send_request).once.with('docs.getSettings', hash_including(:doc_id => 123)).and_return(@xml)
        Scribd::Document.find 123
      end
      
      it "should pass other options to the getSettings call" do
        Scribd::API.instance.should_receive(:send_request).once.with('docs.getSettings', hash_including(:arg => 'val')).and_return(@xml)
        Scribd::Document.find 123, :arg => 'val'
      end
      
      it "should return a Document created from the resulting XML" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        doc = Scribd::Document.find(123)
        doc.should be_kind_of(Scribd::Document)
        doc.access_key.should eql('abc123')
      end
    end
    
    describe "by query" do
      before :each do
        @xml = REXML::Document.new("<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>")
      end
      
      it "should set the scope field according to the parameter" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:scope => 'all')).and_return(@xml)
        Scribd::Document.find(:all, :query => 'test')
      end
      
      it "should return an ordered array of Document results" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        docs = Scribd::Document.find(:all, :query => 'test')
        docs.should have(2).items
        docs.first.access_key.should eql('abc123')
        docs.last.access_key.should eql('abc321')
      end
      
      it "should set the scope to 'all' and return the first result if :first is provided" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:scope => 'all')).and_return(@xml)
        docs = Scribd::Document.find(:first, :query => 'test')
        docs.should be_kind_of(Scribd::Document)
        docs.access_key.should eql('abc123')
      end
      
      it "should set the num_results field to the limit option" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:num_results => 10)).and_return(@xml)
        docs = Scribd::Document.find(:all, :query => 'test', :limit => 10)
      end
      
      it "should set the num_start field to the offset option" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:num_start => 10)).and_return(@xml)
        docs = Scribd::Document.find(:all, :query => 'test', :offset => 10)
      end
    end
  end
  
  it "should have an upload synonym for the create method"
  
  describe ".conversion_status" do
    before :each do
      @document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
      @xml = REXML::Document.new("<rsp stat='ok'><conversion_status>EXAMPLE</conversion_status></rsp>")
    end
    
    it "should call getConversionStatus with the correct doc_id" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getConversionStatus', :doc_id => 123).and_return(@xml)
      @document.conversion_status
    end
    
    it "should return the conversion status" do
      Scribd::API.instance.stub!(:send_request).and_return(@xml)
      @document.conversion_status.should eql('EXAMPLE')
    end
  end
  
  describe ".destroy" do
    before :each do
      @document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
      @success = REXML::Document.new("<rsp stat='ok' />")
      @fail = REXML::Document.new("<rsp stat='fail' />")
    end
    
    it "should call delete with the correct doc_id" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.delete', :doc_id => 123).and_return(@success)
      @document.destroy
    end
    
    it "should return true if successful" do
      Scribd::API.instance.stub!(:send_request).and_return(@success)
      @document.destroy.should be_true
    end
    
    it "should return false if unsuccessful" do
      Scribd::API.instance.stub!(:send_request).and_return(@fail)
      @document.destroy.should be_false
    end
  end
  
  it "should have an id attribute that aliases doc_id" do
    document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
    document.id.should eql(123)
  end
  
  describe ".owner=" do
    it "should raise NotImplementedError for saved docs" do
      document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
      lambda { document.owner = Scribd::User.new }.should raise_error(NotImplementedError)
    end
  end
  
  describe ".download_url" do
    before :each do
      @document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
      @xml = REXML::Document.new("<rsp stat='ok'><download_link><![CDATA[http://www.example.com/doc.pdf]]></download_link></rsp>")
    end
    
    it "should call docs.getDownloadUrl with the correct doc_id" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getDownloadUrl', hash_including(:doc_id => 123)).and_return(@xml)
      @document.download_url
    end
    
    it "should default to the original file format" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getDownloadUrl', hash_including(:doc_type => 'original')).and_return(@xml)
      @document.download_url
    end
    
    it "should allow custom file formats" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getDownloadUrl', hash_including(:doc_type => 'pdf')).and_return(@xml)
      @document.download_url('pdf')
    end
    
    it "should return the download link" do
      Scribd::API.instance.stub!(:send_request).and_return(@xml)
      @document.download_url.should eql("http://www.example.com/doc.pdf")
    end
  end
end

Dir.chdir old_dir
