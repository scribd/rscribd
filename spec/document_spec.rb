require 'spec_helper'

describe Scribd::Document do
  before do
    Scribd::API.key = 'test key'
    Scribd::API.secret = 'test sec'
  end
  
  describe "#initialize" do
    context "from attributes" do
      subject { Scribd::Document.new(:access => 'private', :title => 'mytitle') }
    
      its(:access) { should == 'private' }
      its(:title) { should == 'mytitle' }
      it { should_not be_saved }
      it { should_not be_created }
    end
  
    context "initialized from XML" do
      let(:owner) { double('Scribd::User @owner') }
      let(:xml) { Nokogiri::XML("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root }
      
      subject { Scribd::Document.new(:xml => xml, :owner => owner) }
    
      its(:attr1) { should == 'val1' }
      its(:attr2) { should == 'val2' }
      its(:owner) { should == owner }
      
      it { should be_saved }
      it { should be_created }
    end
  end
  
  describe "#save" do
    subject { @document.save }
    
    describe "when not yet created" do
      before do
        @document = Scribd::Document.new(:access => 'private', :title => 'mytitle')
      end
      
      it { expect { subject }.should raise_error }
    end
    
    context "when created" do
      let(:owner) { double('Scribd::User @owner') }
      
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "xml=%3Crsp%20stat%3D%22ok%22%3E%0A%20%20%3Cattr1%3Eval1%3C%2Fattr1%3E%0A%20%20%3Cattr2%3Eval2%3C%2Fattr2%3E%0A%3C%2Frsp%3E&attr1=val1&attr2=val2&method=docs.changeSettings&api_key=test%20key&api_sig=d649ff81ab68d725cc49b59354495b21")
          .to_return(:body => "<rsp stat='ok' />")
        
        @document = Scribd::Document.new(:xml => Nokogiri::XML("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root)
      end
    
      it "should not raise an exception if saved" do
        expect { subject }.to_not raise_error
      end
    
      context "that we own" do
        before do
          stub_request(:post, "http://api.scribd.com/api")
                 .with(:body => "xml=%3Crsp%20stat%3D%22ok%22%3E%0A%20%20%3Cattr1%3Eval1%3C%2Fattr1%3E%0A%20%20%3Cattr2%3Eval2%3C%2Fattr2%3E%0A%3C%2Frsp%3E&attr1=val1&attr2=val2&method=docs.changeSettings&api_key=test%20key&api_sig=d649ff81ab68d725cc49b59354495b21")
            .to_return(:body => "<rsp stat='ok' />")
            
          owner.stub!(:session_key).and_return('test session key')
          @document = Scribd::Document.new(:xml => Nokogiri::XML("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root, :owner => owner)
        end
        it { expect { subject }.to_not raise_error }
      end
    
      context "that we don't own" do
        before do
          owner.stub!(:session_key)
          @document = Scribd::Document.new(:xml => Nokogiri::XML("<rsp stat='ok'><attr1>val1</attr1><attr2>val2</attr2></rsp>").root, :owner => owner)
        end
      
        context "when trying to change the file" do
          before { @document.file = 'sample/test.txt' }
          it { expect { subject }.to raise_error(Scribd::PrivilegeError) }
        end
      end
    
      context "with no owner" do      
        context "when trying to change the file" do
          before { @document.file = 'sample/test.txt' }
          it { expect { subject }.to raise_error(Scribd::PrivilegeError) }
        end
      end
      
      context "when uploading from file" do
        before do          
          @document = Scribd::Document.new(:file => 'sample/test.txt')
          
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
             to_return(:body => "<rsp stat='ok' />")

          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
             to_return(:body => "<rsp stat='ok' />")
        end
        
        it { should be_true }
      end
      
      context "when uploading from URL" do        
        context "when file come within HTTP" do
          before do
            @document = Scribd::Document.new(:file => 'http://www.example.com/file.txt')
            
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "url=http%3A%2F%2Fwww.example.com%2Ffile.txt&method=docs.uploadFromUrl&api_key=test%20key&api_sig=c3541eba247950aa05e9c1350883fd4a").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { should be_true }
        end

        context "when file come within HTTPS" do
          before do
            @document = Scribd::Document.new(:file => 'https://www.example.com/file.txt')
            
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "url=https%3A%2F%2Fwww.example.com%2Ffile.txt&method=docs.uploadFromUrl&api_key=test%20key&api_sig=343dd238c861310266f8bbc3599892fb").
               to_return(:body => "<rsp stat='ok' />")
            
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { should be_true }
        end

        context "when file come within FTP" do
          before do
            @document = Scribd::Document.new(:file => 'ftp://www.example.com/file.txt')
            
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "url=ftp%3A%2F%2Fwww.example.com%2Ffile.txt&method=docs.uploadFromUrl&api_key=test%20key&api_sig=b39a9ee5feeb10977958fa24b9b38c61").
               to_return(:body => "<rsp stat='ok' />")
               
           stub_request(:post, "http://api.scribd.com/api").
                   with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
              to_return(:body => "<rsp stat='ok' />")
          end

          it { should be_true }
        end
      end
    end
  
    context "detecting the file extension" do      
      context "given a file path" do
        before do
          @document = Scribd::Document.new(:file => 'sample/test.txt')
        end
      
        context "when the file extension is txt" do
          before do
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end
        
          it { should be_true }
        end

        context "when the doc_type set in the type attribute" do
          before do
            @document.type = 'pdf'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&doc_type=pdf&method=docs.upload&api_key=test%20key&api_sig=c1300e23a70fa27e230bf97cafb73b71").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end
        
          it { should be_true }
        end

        context "when the document does not have an extension" do
          before do
            @document.file = 'Rakefile'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=Rakefile&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end
        
          it { should be_true }
        end

        context "when filename extensions is uppercase" do
          before do
            @document.file = 'sample/test.TXT'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.TXT&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end
        
          it { should be_true }
        end

        context "when the type attribute is uppercase" do
          before do
            @document.type = 'PDF'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&doc_type=pdf&method=docs.upload&api_key=test%20key&api_sig=c1300e23a70fa27e230bf97cafb73b71").
               to_return(:body => "<rsp stat='ok' />")
               
             stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
                to_return(:body => "<rsp stat='ok' />")
          end
        
          it { should be_true }
        end
      end
    
      describe "given a file object" do
        before do
          @document = Scribd::Document.new(:file => File.new('sample/test.txt'))
        end

        context "when the extension is txt" do
          before do
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { should be_true }
        end

        context "when the doc_type is set in the type attribute" do
          before do
            @document.type = 'pdf'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&doc_type=pdf&method=docs.upload&api_key=test%20key&api_sig=c1300e23a70fa27e230bf97cafb73b71").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { should be_true }
        end

        context "if the document does not have an extension" do
          before do
            @document.file = File.open('Rakefile')
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=Rakefile&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
                     
            Scribd::API.should_receive(:send_request).any_number_of_times
          end

          it { expect { subject }.to_not raise_error }
        end

        context "downcase filename extensions" do
          before do
            @document.file = File.open('sample/test.TXT')
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.TXT&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { expect { subject }.to_not raise_error }
        end

        context "downcase attributed file extensions" do
          before do
            @document.type = 'PDF'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&doc_type=pdf&method=docs.upload&api_key=test%20key&api_sig=c1300e23a70fa27e230bf97cafb73b71").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
          end

          it { expect { subject }.to_not raise_error }
        end

        describe "given a file to upload" do
          before do
            @document = Scribd::Document.new(:file => 'sample/test.txt')
          end
      
          it "should set the rev_id field to the doc_id attribute" do
            @document.doc_id = 123
            stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "file=sample%2Ftest.txt&rev_id=123&method=docs.upload&api_key=test%20key&api_sig=4e3b8c1ed58791c99b5fb067ea0508bf").
                     to_return(:body => "<rsp stat='ok' />")
            stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "doc_id=123&doc_ids=123&method=docs.changeSettings&api_key=test%20key&api_sig=1fd7dd6c76a5a0a64d8b5c3e124f9142").
                     to_return(:body => "<rsp stat='ok' />")
            subject
          end

          it "should set the access field to the access attribute" do
            @document.access = 'private'
            stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "file=sample%2Ftest.txt&access=private&method=docs.upload&api_key=test%20key&api_sig=709936b4f4be31a2fd8533601e25f6bf").
                     to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
                     to_return(:body => "<rsp stat='ok' />")
                     
            subject
          end

          it "should set the session_key field to the owner's session key" do
            owner = mock('Scribd::User owner')
            owner.stub!(:session_key).and_return('his key')
            @document.owner = owner
            stub_request(:post, "http://api.scribd.com/api").
                     with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
                to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
            
            subject
          end

          it "should pass through any other attributes to the docs.upload call" do
            @document.hello = 'there'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "hello=there&method=docs.changeSettings&api_key=test%20key&api_sig=bc47f5fda03ed77002569ba21108449c").
               to_return(:body => "<rsp stat='ok' />")
                     
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&hello=there&method=docs.upload&api_key=test%20key&api_sig=ad08824fffee148c9e50753064514821").
               to_return(:body => "<rsp stat='ok' />")
            
            subject
          end

          it "should not pass the thumbnail option to the docs.upload call" do
            @document.thumbnail = 'sample/test.txt'
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "file=sample%2Ftest.txt&method=docs.uploadThumb&api_key=test%20key&api_sig=cf55b38424a02b3f043df38f58d80057").
               to_return(:body => "<rsp stat='ok' />")
               
            stub_request(:post, "http://api.scribd.com/api").
                    with(:body => "method=docs.changeSettings&api_key=test%20key&api_sig=f1e05901b2045c5811be00be002309f8").
               to_return(:body => "<rsp stat='ok' />")
            
            subject
          end

          describe "successfully" do
            before do
              @document.stub!(:id).and_return(3)
              
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&access=private&doc_type=pdf&method=docs.upload&api_key=test%20key&api_sig=ac80d14c4bee27eea1bcda3237331552").
                 to_return(:body => "<rsp stat='ok' />")
            end

            describe "without testing changeSettings" do
              before do
                stub_request(:post, "http://api.scribd.com/api").
                        with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
                   to_return(:body => "<rsp stat='ok'><access_key>abc123</access_key></rsp>")
                
                stub_request(:post, "http://api.scribd.com/api").
                        with(:body => "access_key=abc123&doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=17033f3a2bd7b4f723b365154626a37e").
                   to_return(:body => "<rsp stat='ok' />")
              end

              it "should load attributes from the response" do
                subject
                @document.access_key.should eql('abc123')
              end

              it "should set created to true" do
                subject
                @document.should be_created
              end

              it "should set saved to true" do
                subject
                @document.should be_saved
              end

              it "should return true" do
                subject.should be_true
              end

              describe "with a File thumbnail" do
                before do
                  @document.thumbnail = File.open("sample/test.txt")
                end

                it "should call docs.uploadThumb with the File object" do
                  stub_request(:post, "http://api.scribd.com/api").
                          with(:body => "file=sample%2Ftest.txt&doc_id=3&method=docs.uploadThumb&api_key=test%20key&api_sig=04c4f466c7c4ddeb97bf94d7def0d2c9").
                     to_return(:body => "<rsp stat='ok' />")
                     
                  subject
                end
              end

              describe "with a URL thumbnail" do
                before do
                  @document.thumbnail = "http://www.scribd.com/favicon.ico"
                end

                it "should open a stream for the URL and pass it to docs.uploadThumb" do
                  tempfile = double('tempfile', :binmode => true, :path => "/tmp/thumb")
                  tempfile.should_receive(:write).with('thumb-image')
                  Tempfile.should_receive(:new).and_return(tempfile)
                  
                  stub_request(:get, "http://www.scribd.com/favicon.ico").to_return(:body => "thumb-image")
                  
                  stub_request(:post, "http://api.scribd.com/api").
                          with(:body => "file=%2Ftmp%2Fthumb&doc_id=3&method=docs.uploadThumb&api_key=test%20key&api_sig=04c4f466c7c4ddeb97bf94d7def0d2c9").
                     to_return(:body => "<rsp stat='ok' />")
                  
                  subject
                end
              end
            end

            it "should not send the file, type, or access parameters to the changeSettings call" do
              @document.type = 'pdf'
              @document.access = 'private'
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=e1b1bc9bf2e406308c2d8804c5519638").
                 to_return(:body => "<rsp stat='ok' />")
              
              subject
            end

            it "should pass all other attributes to the changeSettings call" do
              @document.attr1 = 'val1'
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&attr1=val1&method=docs.upload&api_key=test%20key&api_sig=8d87c1d925d26bd378656bd0355f2031").
                 to_return(:body => "<rsp stat='ok' />")
                 
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "attr1=val1&doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=f93463020d6ee5a450a9aefd060ddfaf").
                 to_return(:body => "<rsp stat='ok' />")
                 
              subject
            end

            it "should not pass thumbnail to the changeSettings call" do
              @document.thumbnail = 'sample/test.txt'
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
                 to_return(:body => "<rsp stat='ok' />")
                       
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&doc_id=3&method=docs.uploadThumb&api_key=test%20key&api_sig=04c4f466c7c4ddeb97bf94d7def0d2c9").
                 to_return(:body => "<rsp stat='ok' />")
                 
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=e1b1bc9bf2e406308c2d8804c5519638").
                 to_return(:body => "<rsp stat='ok' />")
                       
              subject
            end

            it "should pass the owner's session key to changeSettings" do
              owner = mock('Scribd::User owner')
              owner.stub!(:session_key).and_return('his key')
              @document.owner = owner
              
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
                 to_return(:body => "<rsp stat='ok' />")
                 
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=e1b1bc9bf2e406308c2d8804c5519638").
                 to_return(:body => "<rsp stat='ok' />")
              
              subject
            end

            it "should pass the document's ID to changeSettings" do
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "file=sample%2Ftest.txt&method=docs.upload&api_key=test%20key&api_sig=c04a62f53e77d6449a80c8c4b4212ed6").
                 to_return(:body => "<rsp stat='ok' />")
                 
              stub_request(:post, "http://api.scribd.com/api").
                      with(:body => "doc_ids=3&method=docs.changeSettings&api_key=test%20key&api_sig=e1b1bc9bf2e406308c2d8804c5519638").
                 to_return(:body => "<rsp stat='ok' />")
                 
              subject
            end
          end
        end
      end
    end
  
    describe ".update_all" do
      before do
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
        Scribd::API.should_receive(:request).once.with('docs.changeSettings', hash_including(:session_key => 'session1'))
        Scribd::API.should_receive(:request).once.with('docs.changeSettings', hash_including(:session_key => 'session2'))
        Scribd::Document.update_all @docs, { :access => 'private' }
      end
    
      it "should set the doc_ids field to a comma-delimited list of document IDs" do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "access=private&doc_ids=1%2C2&method=docs.changeSettings&api_key=test%20key&api_sig=a4a3f20197e9d62114330bfb51f56415").
           to_return(:body => "<rsp stat='ok' />")
        
        Scribd::Document.update_all @docs, { :access => 'private' }
      end
    
      it "should pass all options to the changeSettings call" do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "access=private&bogus=test&doc_ids=1%2C2&method=docs.changeSettings&api_key=test%20key&api_sig=42ff272580ae78642b4f5957197671c4").
           to_return(:body => "<rsp stat='ok' />")
                 
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
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "doc_id=123&method=docs.getSettings&api_key=test%20key&api_sig=40fbe0685b2b3fef7959c29a00376d41").
             to_return(:body => "<rsp stat='ok'><access_key>abc123</access_key></rsp>")
        end
        
        subject { Scribd::Document.find(123) }
        
        it { should be_kind_of Scribd::Document }
        its(:access_key) { should == 'abc123' }
      end
    
      describe "by query" do
        let(:response) { "<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>" }
      
        it "should return an ordered array of Document results" do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "query=test&method=docs.search&api_key=test%20key&api_sig=13a369e85fdfd0da17e289e219cea6b4").
             to_return(:body => response)
                   
          docs = Scribd::Document.find(:query => 'test')
          docs.should have(2).items
          docs.first.access_key.should == 'abc123'
          docs.last.access_key.should == 'abc321'
        end
      
        it "should set the num_results field to the limit option" do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "query=test&limit=10&num_results=10&method=docs.search&api_key=test%20key&api_sig=bee99ea8e8397c677504d077b8f1b82f").
             to_return(:body => response)
          
          Scribd::Document.find(:query => 'test', :limit => 10)
        end
      
        it "should set the num_start field to the offset option" do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "query=test&offset=10&num_start=10&method=docs.search&api_key=test%20key&api_sig=0573a2b75ab232ced397e81c431bb829").
             to_return(:body => response)
             
          Scribd::Document.find(:query => 'test', :offset => 10)
        end
      end
    end
  end

  describe ".featured" do
    let(:response) { "<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>" }

    it "should call the docs.featured API method" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "method=docs.featured&api_key=test%20key&api_sig=dca8642e3d355f0b8f1334394fea99b8").
         to_return(:body => response)
               
      docs = Scribd::Document.featured
      docs.should be_kind_of(Array)
      docs.first.should be_kind_of(Scribd::Document)
      docs.first.access_key.should == 'abc123'
    end
  
    it "should pass options to the API" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "foo=bar&method=docs.featured&api_key=test%20key&api_sig=3a65d9777718ae53a31cde86e6c82d73").
         to_return(:body => response)
               
      Scribd::Document.featured(:foo => 'bar')
    end
  end

  describe ".browse" do
    let(:response) { "<rsp stat='ok'><result_set><result><access_key>abc123</access_key></result><result><access_key>abc321</access_key></result></result_set></rsp>" }

    it "should call the docs.browse method" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "method=docs.browse&api_key=test%20key&api_sig=bada607427890abfee95e21ddbdf5103").
         to_return(:body => response)
               
      docs = Scribd::Document.browse
      docs.should be_kind_of(Array)
      docs.first.should be_kind_of(Scribd::Document)        
      docs.first.access_key.should == 'abc123'
    end
  
    it "should pass options to the API" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "foo=bar&method=docs.browse&api_key=test%20key&api_sig=cb8f758261a7aa996f1d4964b18c21a3").
         to_return(:body => response)
               
      Scribd::Document.browse(:foo => 'bar')
    end
  end

  describe ".conversion_status" do
    before do
      @document = Scribd::Document.new(:xml => Nokogiri::XML("<doc_id type='integer'>123</doc_id>"))
      
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=docs.getConversionStatus&api_key=test%20key&api_sig=f07e7716162e68fdd99af6d5ca6e2242").
         to_return(:body => "<rsp stat='ok'><conversion_status>EXAMPLE</conversion_status></rsp>")
    end
  
    subject { @document.conversion_status }
    it { should == 'EXAMPLE' }
  end

  describe ".reads" do
    before do
      @document = Scribd::Document.new(:xml => Nokogiri::XML("<doc_id type='integer'>123</doc_id>"))
      
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=docs.getStats&api_key=test%20key&api_sig=345a6e79eaa2f8624116453c6f239c20").
         to_return(:body => "<rsp stat='ok'><reads>12321</reads></rsp>")
    end
    
    subject { @document.reads }

    it { should == '12321' }

    it "should call getStats only once when read call made more than once" do
      Scribd::API.should_receive(:request).once.with('docs.getStats', :doc_id => 123).and_return(Nokogiri::XML("<rsp stat='ok'><reads>12321</reads></rsp>"))
      2.times { subject }
    end

    it "should call getStats everytime when read call made with :force => true" do
      Scribd::API.should_receive(:request).twice.with('docs.getStats', :doc_id => 123).and_return(Nokogiri::XML("<rsp stat='ok'><reads>12321</reads></rsp>"))
      @document.reads
      @document.reads(:force => true)
    end
  end

  describe ".destroy" do
    before do
      @document = Scribd::Document.new(:xml => Nokogiri::XML("<doc_id type='integer'>123</doc_id>"))
    end
  
    subject { @document.destroy }
  
    context "when the response is ok" do
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "doc_id=123&method=docs.delete&api_key=test%20key&api_sig=e9481a43f5897455bacabd0638e22156").
           to_return(:body => "<rsp stat='ok' />")
      end
      
      it { should be_true }
    end
    
    context "when the response is fail" do
      before do
        stub_request(:post, "http://api.scribd.com/api").
                with(:body => "doc_id=123&method=docs.delete&api_key=test%20key&api_sig=e9481a43f5897455bacabd0638e22156").
           to_return(:body => "<rsp stat='fail'><error /><rsp />")
      end
      
      it { should be_false }
    end
  end

  describe "#id" do
    subject { Scribd::Document.new(:xml => Nokogiri::XML("<doc_id type='integer'>123</doc_id>")).id }
    it { should == 123 }
  end

  describe ".download_url" do
    before do
      @document = Scribd::Document.new(:xml => Nokogiri::XML("<doc_id type='integer'>123</doc_id>"))
    end
  
    it "should call docs.getDownloadUrl with the correct doc_id" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&doc_type=original&method=docs.getDownloadUrl&api_key=test%20key&api_sig=54061a63d7cc488a90e4373d14ec664c").
         to_return(:body => "<rsp stat='ok'><download_link><![CDATA[http://www.example.com/doc.pdf]]></download_link></rsp>")
         
      @document.download_url
    end
  
    it "should allow custom file formats" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&doc_type=pdf&method=docs.getDownloadUrl&api_key=test%20key&api_sig=50377d80f99f54b0751ecdf6c49e4684").
         to_return(:body => "<rsp stat='ok'><download_link><![CDATA[http://www.example.com/doc.pdf]]></download_link></rsp>")
               
      @document.download_url('pdf').should eql("http://www.example.com/doc.pdf")
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
    before do
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
    before do
      @url = "http://imgv2-2.scribdassets.com/img/word_document/1/111x142/ff94c77a69/1277782307"
      @response = <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
          <thumbnail_url>#{@url}</thumbnail_url>
        </rsp>
      EOF
    end
  
    it "should raise an exception if both width/height and size are specified" do
      lambda { Scribd::Document.thumbnail_url(123, :width => 123, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :height => 123, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :width => 123, :height => 321, :size => [ 1, 2 ]) }.should raise_error(ArgumentError)
    end
  
    it "should raise an exception if size is not an array" do
      lambda { Scribd::Document.thumbnail_url(123, :size => 123) }.should raise_error(ArgumentError)
    end
  
    it "should raise an exception if size is not 2 elements long" do
      lambda { Scribd::Document.thumbnail_url(123, :size => [ 1 ]) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :size => [ 1, 2, 3 ]) }.should raise_error(ArgumentError)
    end
  
    it "should raise an exception if either width xor height is specified" do
      lambda { Scribd::Document.thumbnail_url(123, :width => 123) }.should raise_error(ArgumentError)
      lambda { Scribd::Document.thumbnail_url(123, :height => 123) }.should raise_error(ArgumentError)
    end
  
    it "should call the thumbnail.get API method" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&method=thumbnail.get&api_key=test%20key&api_sig=20e2d482f4760bb783d49159da40a7c9").
         to_return(:body => @response)
               
      Scribd::Document.thumbnail_url(123).should eql(@url)
    end
  
    it "should pass the width and height" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&width=2&height=4&method=thumbnail.get&api_key=test%20key&api_sig=87a1d9b8307ceecb3cc29a929d8b961f").
         to_return(:body => @response)
               
      Scribd::Document.thumbnail_url(123, :width => 2, :height => 4).should eql(@url)
    end
  
    it "should pass a size" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&width=2&height=4&method=thumbnail.get&api_key=test%20key&api_sig=87a1d9b8307ceecb3cc29a929d8b961f").
         to_return(:body => @response)
               
      Scribd::Document.thumbnail_url(123, :size => [ 2, 4 ]).should eql(@url)
    end
  
    it "should pass the page number" do
      stub_request(:post, "http://api.scribd.com/api").
              with(:body => "doc_id=123&page=10&method=thumbnail.get&api_key=test%20key&api_sig=9b4a1c077fb464d671c3ba45b53d583f").
         to_return(:body => @response)
               
      Scribd::Document.thumbnail_url(123, :page => 10).should eql(@url)
    end
  end
end