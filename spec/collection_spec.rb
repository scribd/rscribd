require 'spec_helper'

describe Scribd::Collection do
  before do
    Scribd::API.key = 'test key'
    Scribd::API.secret = 'test sec'
  end
  
  let(:collection_xml) { Nokogiri::XML("<result><collection_id>61</collection_id><collection_name>My Collection</collection_name></result>").root }
  let(:user) { Scribd::User.new(:xml => Nokogiri::XML("<rsp stat='ok'><user_id type='integer'>225</user_id><username>sancho</username><name>Sancho Sample</name><session_key>some key</session_key></rsp>").root) }
  let(:collection) { Scribd::Collection.new(:xml => collection_xml, :owner => user) }
  
  let(:good_response) { %q{<?xml version="1.0" encoding="UTF-8"?><rsp stat="ok" />} }
  let(:document) { Scribd::Document.new(:doc_id => '123') }
  
  describe "#initialize" do
    context "from XML" do
      subject { collection }
      
      it { should be_saved }
      it { should be_created }
      
      its(:collection_id) { should eql("61") }
      its(:collection_name) { should eql("My Collection") }
      its(:owner) { should == user }
      its(:id) { should eql('61') }
      its(:name) { should eql('My Collection') }
    end
    
    context "from attributes" do
      subject { Scribd::Collection.new(:collection_id => 61, :collection_name => "My Collection") }
      
      it { expect { subject }.to raise_error }
    end
  end
  
  describe "#add" do
    context "when an invalid document is given" do
      subject { collection.add(123) }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context "when a valid document is given" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "collection_id=61&doc_id=123&method=docs.addToCollection&api_key=test%20key&api_sig=a98d80447b2f23b0c80951bf8806fa6c")
          .to_return(:body => good_response)
      end

      subject { collection.add(document) }

      it { should == document }
    end
    
    context "when the call returns code 653" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "collection_id=61&doc_id=123&method=docs.addToCollection&api_key=test%20key&api_sig=a98d80447b2f23b0c80951bf8806fa6c")
          .to_return(:body => "<rsp stat='fail'><error code='653' /></rsp>", :status => 653)
      end
      
      context "and ignore_if_exists is true" do
        subject { collection.add(document) }
        it { expect { subject }.to_not raise_error }
      end
      
      context "and ignore_if_exists is false" do
        subject { collection.add(document, false) }
        it { expect { subject }.to raise_error(Scribd::ResponseError) }
      end
    end
    
    context "when the call returns other errors" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "collection_id=61&doc_id=123&method=docs.addToCollection&api_key=test%20key&api_sig=a98d80447b2f23b0c80951bf8806fa6c")
          .to_return(:body => "<rsp stat='fail'><error code='652' /></rsp>", :status => 652)
      end
      
      context "and the ignore_if_exists is true" do
        subject { collection.add(document) }
        it { expect { subject }.to raise_error(Scribd::ResponseError) }
      end
      
      context "and the ignore_if_exists is false" do
        subject { collection.add(document, false) }
        it { expect { subject }.to raise_error(Scribd::ResponseError) }
      end
    end
  end
  
  describe "#<<" do
    it "should call #add" do
      collection.should_receive(:add).with(document).and_return(document)
      (collection << document).should eql(document)
    end
  end
  
  describe "#remove" do
    context "when the document is invalid" do
      subject { collection.remove(123) }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context "when the document is valid" do
      context "and the response is successful" do
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "collection_id=61&doc_id=123&method=docs.removeFromCollection&api_key=test%20key&api_sig=3bf57a89434777761a91e8aeb1872a41").
             to_return(:body => good_response)
        end
        
        subject { collection.remove(document) }
        it { should == document }
      end
      
      context "and the response returns code 652" do
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "collection_id=61&doc_id=123&method=docs.removeFromCollection&api_key=test%20key&api_sig=3bf57a89434777761a91e8aeb1872a41").
             to_return(:body => "<rsp stat='fail'><error code='652' /></rsp>", :status => 652)
        end
        
        context "and ignore_if_missing is true" do
          subject { collection.remove(document) }
          it { expect { subject }.to_not raise_error }
        end
        
        context "and ignore_if_missing is false" do
          subject { collection.remove(document, false) }
          it { expect { subject }.should raise_error(Scribd::ResponseError) }
        end
      end
      
      context "and the response returns other code" do
        before do
          stub_request(:post, "http://api.scribd.com/api").
                  with(:body => "collection_id=61&doc_id=123&method=docs.removeFromCollection&api_key=test%20key&api_sig=3bf57a89434777761a91e8aeb1872a41").
             to_return(:body => "<rsp stat='fail'><error code='653' /></rsp>", :status => 653)
        end
        
        context "and ignore_if_missing is true" do
          subject { collection.remove(document) }
          it { expect { subject }.to raise_error(Scribd::ResponseError) }
        end
        
        context "and ignore_if_missing is false" do
          subject { collection.remove(document, false) }
          it { expect { subject }.to raise_error(Scribd::ResponseError) }
        end
      end
    end
  end
end
