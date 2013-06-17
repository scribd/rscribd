require 'spec_helper'

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
      @http.stub!(:started?).and_return(false)
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

    it "should recognize URLs with square brackets" do
      @document.file = 'http://www.example.com/file[].txt'
      Scribd::API.instance.should_receive(:send_request).with('docs.uploadFromUrl', hash_including(:url => 'http://www.example.com/file%5B%5D.txt'))
      Scribd::API.instance.should_receive(:send_request).any_number_of_times
      @document.save
    end
  end
  
  describe "to be uploaded" do
    describe "given a file path" do
      before :each do
        @document = Scribd::Document.new(:file => 'sample/test.txt')
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
    end
    
    describe "given a file object" do
      before :each do
        @document = Scribd::Document.new(:file => File.new('sample/test.txt'))
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
        @document.file = File.open('Rakefile')
        Scribd::API.instance.should_receive(:send_request).with('docs.upload', hash_including(:doc_type => nil))
        Scribd::API.instance.should_receive(:send_request).any_number_of_times
        lambda { @document.save }.should_not raise_error
      end

      it "should downcase filename extensions" do
        @document.file = File.open('sample/test.TXT')
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
    end
    
    describe "given a file to upload" do
      before :each do
        @document = Scribd::Document.new(:file => 'sample/test.txt')
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

      it "should not pass the thumbnail option to the docs.upload call" do
        @document.thumbnail = 'sample/test.txt'
        Scribd::API.instance.should_receive(:send_request).once.with('docs.upload', hash_not_including(:thumbnail))
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

          describe "with a path thumbnail" do
            before :each do
              @document.thumbnail = "sample/image.jpg"
            end

            it "should call docs.uploadThumb with a File object from the path" do
              file_mock = mock('File (thumb)', :close => nil)
              File.should_receive(:open).with(@document.thumbnail, 'rb').and_return(file_mock)
              File.should_receive(:open).any_number_of_times.and_return(mock('File (content)', :close => nil))

              Scribd::API.instance.should_receive(:send_request).once.with('docs.uploadThumb', :file => file_mock, :doc_id => 3)
              Scribd::API.instance.should_receive(:send_request).any_number_of_times
              
              @document.save
            end
          end

          describe "with a File thumbnail" do
            before :each do
              @document.thumbnail = File.open("sample/test.txt")
            end

            it "should call docs.uploadThumb with the File object" do
              Scribd::API.instance.should_receive(:send_request).once.with('docs.uploadThumb', :file => @document.thumbnail, :doc_id => 3)
              Scribd::API.instance.should_receive(:send_request).any_number_of_times
              @document.save
            end
          end

          describe "with a URL thumbnail" do
            before :each do
              @document.thumbnail = "http://www.scribd.com/favicon.ico"
            end

            it "should open a stream for the URL and pass it to docs.uploadThumb" do
              stream_mock = mock('open-uri stream', :close => nil)
              @document.should_receive(:open).once.with(an_instance_of(URI::HTTP)).and_return(stream_mock)
              Scribd::API.instance.should_receive(:send_request).once.with('docs.uploadThumb', :file => stream_mock, :doc_id => 3)
              Scribd::API.instance.should_receive(:send_request).any_number_of_times
              @document.save
            end

            it "should recognize URLs with square brackets" do
              @document.thumbnail = "http://www.scribd.com/favicon[].ico"
              stream_mock = mock('open-uri stream', :close => nil)
              @document.should_receive(:open).once.with(an_instance_of(URI::HTTP)).and_return(stream_mock)
              Scribd::API.instance.should_receive(:send_request).once.with('docs.uploadThumb', :file => stream_mock, :doc_id => 3)
              Scribd::API.instance.should_receive(:send_request).any_number_of_times
              @document.save
            end
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

        it "should not pass thumbnail to the changeSettings call" do
          @document.thumbnail = 'sample/test.txt'
          Scribd::API.instance.should_receive(:send_request).with('docs.changeSettings', hash_not_including(:thumbnail))
          Scribd::API.instance.should_receive(:send_request).any_number_of_times
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
    
    it "should raise an ArgumentError if a query is not provided for non-ID lookups" do
      lambda { Scribd::Document.find(:title => 'hi') }.should raise_error(ArgumentError)
    end
    
    describe "by ID" do
      before :each do
        @xml = REXML::Document.new("<rsp stat='ok'><access_key>abc123</access_key></rsp>")
      end
      
      it "should call getSettings with the doc ID" do
        Scribd::API.instance.should_receive(:send_request).once.with('docs.getSettings', hash_including(:doc_id => 123)).and_return(@xml)
        Scribd::Document.find 123
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
      
      it "should return an ordered array of Document results" do
        Scribd::API.instance.stub!(:send_request).and_return(@xml)
        docs = Scribd::Document.find(:query => 'test')
        docs.should have(2).items
        docs.first.access_key.should eql('abc123')
        docs.last.access_key.should eql('abc321')
      end
      
      it "should set the num_results field to the limit option" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:num_results => 10)).and_return(@xml)
        docs = Scribd::Document.find(:query => 'test', :limit => 10)
      end
      
      it "should set the num_start field to the offset option" do
        Scribd::API.instance.should_receive(:send_request).with('docs.search', hash_including(:num_start => 10)).and_return(@xml)
        docs = Scribd::Document.find(:query => 'test', :offset => 10)
      end
    end
  end

  describe ".featured" do
    before :each do
      @xml = REXML::Document.new("<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>")
    end

    it "should call the docs.featured API method" do
      Scribd::API.instance.should_receive(:send_request).with('docs.featured', {}).and_return(@xml)
      docs = Scribd::Document.featured
      docs.should be_kind_of(Array)
      docs.first.should be_kind_of(Scribd::Document)
      docs.first.access_key.should eql('abc123')
    end
    
    it "should pass options to the API" do
      Scribd::API.instance.should_receive(:send_request).with('docs.featured', :foo => 'bar').and_return(@xml)
      docs = Scribd::Document.featured(:foo => 'bar')
    end
  end

  describe ".browse" do
    before :each do
      @xml = REXML::Document.new("<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>")
    end

    it "should call the docs.browse method" do
      Scribd::API.instance.should_receive(:send_request).with('docs.browse', {}).and_return(@xml)
      docs = Scribd::Document.browse
      docs.should be_kind_of(Array)
      docs.first.should be_kind_of(Scribd::Document)
      docs.first.access_key.should eql('abc123')
    end
    
    it "should pass options to the API" do
      Scribd::API.instance.should_receive(:send_request).with('docs.browse', :foo => 'bar').and_return(@xml)
      docs = Scribd::Document.browse(:foo => 'bar')
    end
  end

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

  describe ".reads" do
    before :each do
      @document = Scribd::Document.new(:xml => REXML::Document.new("<doc_id type='integer'>123</doc_id>"))
      @xml = REXML::Document.new("<rsp stat='ok'><reads>12321</reads></rsp>")
    end

    it "should call getStats with the correct doc_id" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getStats', :doc_id => 123).and_return(@xml)
      @document.reads
    end

    it "should return the read count" do
      Scribd::API.instance.stub!(:send_request).and_return(@xml)
      @document.reads.should eql('12321')
    end

    it "should call getStats only once when read call made more than once" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getStats', :doc_id => 123).and_return(@xml)
      @document.reads
      @document.reads
    end

    it "should call getStats everytime when read call made with :force => true" do
      Scribd::API.instance.should_receive(:send_request).twice.with('docs.getStats', :doc_id => 123).and_return(@xml)
      @document.reads
      @document.reads(:force => true)
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
  
  describe "#grant_access" do
    it "should call Scribd::Security.grant_access" do
      doc = Scribd::Document.new
      Scribd::Security.should_receive(:grant_access).once.with('foo', doc)
      doc.grant_access('foo')
    end
  end
  
  describe "#revoke_access" do
    it "should call Scribd::Security.revoke_access" do
      doc = Scribd::Document.new
      Scribd::Security.should_receive(:revoke_access).once.with('foo', doc)
      doc.revoke_access('foo')
    end
  end
  
  describe "#access_list" do
    it "should call Scribd::Security.document_access_list" do
      doc = Scribd::Document.new
      Scribd::Security.should_receive(:document_access_list).once.with(doc)
      doc.access_list
    end
  end
  
  describe "#thumbnail_url" do
    before :each do
      @doc = Scribd::Document.new(:doc_id => 123)
    end
    
    it "should call Scribd::Document.thumbnail_url" do
      Scribd::Document.should_receive(:thumbnail_url).once.with(123, {})
      @doc.thumbnail_url
    end
    
    it "should pass options" do
      Scribd::Document.should_receive(:thumbnail_url).once.with(123, { :page => 10 })
      @doc.thumbnail_url(:page => 10)
    end
  end
  
  describe ".thumbnail_url" do
    before :each do
      @url = "http://imgv2-2.scribdassets.com/img/word_document/1/111x142/ff94c77a69/1277782307"
      @response = REXML::Document.new(<<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
          <thumbnail_url>#{@url}</thumbnail_url>
        </rsp>
      EOF
      )
    end
    
    it "should raise an exception if both width/height and size are specified" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      lambda { Scribd::Document.thumbnail_url(123, :width => 123, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :height => 123, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :width => 123, :height => 321, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
    end
    
    it "should raise an exception if size is not an array" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      lambda { Scribd::Document.thumbnail_url(123, :size => 123) }.should raise_error(ArgumentError)
    end
    
    it "should raise an exception if size is not 2 elements long" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      lambda { Scribd::Document.thumbnail_url(123, :size => [ 1 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :size => [ 1, 2, 3 ]) }.should raise_error(ArgumentError)
    end
    
    it "should raise an exception if either width xor height is specified" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      lambda { Scribd::Document.thumbnail_url(123, :width => 123) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :height => 123) }.should raise_error(ArgumentError)
    end
    
    it "should call the thumbnail.get API method" do
      Scribd::API.instance.should_receive(:send_request).once.with('thumbnail.get', :doc_id => 123).and_return(@response)
      Scribd::Document.thumbnail_url(123).should eql(@url)
    end
    
    it "should pass the width and height" do
      Scribd::API.instance.should_receive(:send_request).once.with('thumbnail.get', :doc_id => 123, :width => 2, :height => 4).and_return(@response)
      Scribd::Document.thumbnail_url(123, :width => 2, :height => 4)
    end
    
    it "should pass a size" do
      Scribd::API.instance.should_receive(:send_request).once.with('thumbnail.get', :doc_id => 123, :width => 2, :height => 4).and_return(@response)
      Scribd::Document.thumbnail_url(123, :size => [ 2, 4 ])
    end
    
    it "should pass the page number" do
      Scribd::API.instance.should_receive(:send_request).once.with('thumbnail.get', :doc_id => 123, :page => 10).and_return(@response)
      Scribd::Document.thumbnail_url(123, :page => 10)
    end
  end
end
