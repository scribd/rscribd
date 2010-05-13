describe Scribd::Collection do
  before :each do
    Scribd::API.instance.key = 'test key'
    Scribd::API.instance.secret = 'test sec'
  end
  
  subject do
    user = Scribd::User.new(:xml => REXML::Document.new("<rsp stat='ok'><user_id type='integer'>225</user_id><username>sancho</username><name>Sancho Sample</name><session_key>some key</session_key></rsp>").root)
    Scribd::Collection.new(:xml => REXML::Document.new("<result><collection_id>61</collection_id><collection_name>My Collection</collection_name></result>").root, :owner => user)
  end
  
  describe "#initialize" do
    context "from XML" do
      its(:collection_id) { should eql("61") }
      its(:collection_name) { should eql("My Collection") }
      it { should be_saved }
      it { should be_created }
      
      it "should set the owner" do
        user = Scribd::User.new
        coll = Scribd::Collection.new(:xml => REXML::Document.new("<result><collection_id>61</collection_id><collection_name>My Collection</collection_name></result>").root, :owner => user)
        coll.owner.should eql(user)
      end
    end
    
    context "from attributes" do
      it "should raise an exception" do
        lambda { Scribd::Collection.new(:collection_id => 61, :collection_name => "My Collection") }.should raise_error
      end
    end
  end
  
  context "aliased attributes" do
    its(:id) { should eql('61') }
    its(:name) { should eql('My Collection') }
  end
  
  describe "#add" do
    before :each do
      @good_response = <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
        </rsp>
      EOF
      @document = Scribd::Document.new(:doc_id => '123')
    end
    
    it "should raise ArgumentError if an invalid document is given" do
      lambda { subject.add(123) }.should raise_error(ArgumentError)
    end
    
    it "should make an API call to docs.addToCollection" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.addToCollection', hash_including(:doc_id => '123', :collection_id => '61', :session_key => 'some key')).and_return(REXML::Document.new(@good_response).root)
      subject.add(@document)
    end
    
    it "should capture ResponseErrors of code 653 if ignore_if_exists is true" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('653'))
      lambda { subject.add(@document) }.should_not raise_error
    end
    
    it "should not capture ResponseErrors of code 653 if ignore_if_exists is false" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('653'))
      lambda { subject.add(@document, false) }.should raise_error(Scribd::ResponseError)
    end
    
    it "should not capture ResponseErrors of other codes" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('652'))
      lambda { subject.add(@document, false) }.should raise_error(Scribd::ResponseError)
      lambda { subject.add(@document) }.should raise_error(Scribd::ResponseError)
    end
    
    it "should return the document" do
      Scribd::API.instance.stub!(:send_request).and_return(REXML::Document.new(@good_response).root)
      subject.add(@document).should eql(@document)
    end
  end
  
  describe "#<<" do
    it "should call #add" do
      doc_mock = mock('Scribd::Document')
      subject.should_receive(:add).once.with(doc_mock).and_return(doc_mock)
      (subject << doc_mock).should eql(doc_mock)
    end
  end
  
  describe "#remove" do
    before :each do
      @good_response = <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
        </rsp>
      EOF
      @document = Scribd::Document.new(:doc_id => '123')
    end
    
    it "should raise ArgumentError if an invalid document is given" do
      lambda { subject.remove(123) }.should raise_error(ArgumentError)
    end
    
    it "should make an API call to docs.removeFromCollection" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.removeFromCollection', hash_including(:doc_id => '123', :collection_id => '61', :session_key => 'some key')).and_return(REXML::Document.new(@good_response).root)
      subject.remove(@document)
    end
    
    it "should capture ResponseErrors of code 652 if ignore_if_missing is true" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('652'))
      lambda { subject.remove(@document) }.should_not raise_error
    end
    
    it "should not capture ResponseErrors of code 653 if ignore_if_missing is false" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('652'))
      lambda { subject.remove(@document, false) }.should raise_error(Scribd::ResponseError)
    end
    
    it "should not capture ResponseErrors of other codes" do
      Scribd::API.instance.stub!(:send_request).and_raise(Scribd::ResponseError.new('653'))
      lambda { subject.remove(@document, false) }.should raise_error(Scribd::ResponseError)
      lambda { subject.remove(@document) }.should raise_error(Scribd::ResponseError)
    end
    
    it "should return the document" do
      Scribd::API.instance.stub!(:send_request).and_return(REXML::Document.new(@good_response).root)
      subject.remove(@document).should eql(@document)
    end
  end
end
