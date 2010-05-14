describe Scribd::Security do
  before :each do
    @document = Scribd::Document.new(:xml => REXML::Document.new('<result><doc_id>123</doc_id></result>').root)
    @ident_list = REXML::Document.new(<<-EOF
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
    ).root
    @doc_list = REXML::Document.new(<<-EOF
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
    ).root
  end
  
  describe :grant_access do
    it "should call set_access" do
      Scribd::Security.should_receive(:set_access).once.with('foo', true, @document)
      Scribd::Security.grant_access('foo', @document)
    end
  end
  
  describe :revoke_access do
    it "should call set_access" do
      Scribd::Security.should_receive(:set_access).once.with('foo', false, @document)
      Scribd::Security.revoke_access('foo', @document)
    end
  end
  
  describe :set_access do
    it "should make an API call to security.setAccess (nil document, access_allowed = 1)" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.setAccess', :user_identifier => 'foo', :allowed => 1)
      Scribd::Security.set_access 'foo', true
    end
    
    it "should set the doc_id when given a Scribd::Document" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.setAccess', :user_identifier => 'foo', :allowed => 1, :doc_id => '123')
      Scribd::Security.set_access 'foo', true, @document
    end
    
    it "should set the doc_id when given a number" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.setAccess', :user_identifier => 'foo', :allowed => 1, :doc_id => 123)
      Scribd::Security.set_access 'foo', true, 123
    end
    
    it "should raise ArgumentError when given anything else" do
      lambda { Scribd::Security.set_access 'foo', true, Object.new }.should raise_error(ArgumentError)
    end
    
    it "should set allowed to 0 when given false" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.setAccess', :user_identifier => 'foo', :allowed => 0)
      Scribd::Security.set_access 'foo', false
    end
  end
  
  describe :document_access_list do
    it "should make an API call to security.getDocumentAccessList with the document ID" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.getDocumentAccessList', :doc_id => '123').and_return(@ident_list)
      Scribd::Security.document_access_list(@document)
    end
    
    it "should accept ID numbers" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.getDocumentAccessList', :doc_id => 123).and_return(@ident_list)
      Scribd::Security.document_access_list(123)
    end
    
    it "should return an array of identifiers" do
      Scribd::API.instance.stub!(:send_request).and_return(@ident_list)
      idents = Scribd::Security.document_access_list(@document)
      idents.should == %w( leila83 spikyhairdude )
    end
  end
  
  describe :user_access_list do
    it "should make an API call to security.getUserAccessList with the document ID" do
      Scribd::API.instance.should_receive(:send_request).once.with('security.getUserAccessList', :user_identifier => '123').and_return(@doc_list)
      Scribd::Security.user_access_list('123')
    end
    
    it "should return an array of documents" do
      Scribd::API.instance.stub!(:send_request).and_return(@doc_list)
      docs = Scribd::Security.user_access_list('123')
      docs.should be_kind_of(Array)
      docs.size.should eql(2)
      docs.each do |doc|
        doc.should be_kind_of(Scribd::Document)
      end
    end
  end
end
