require 'spec_helper'

CATEGORY = Proc.new { |id, name, children|
  id ||= rand(1000)
  name ||= "Test Category #{id}"
  children ||= nil
  
  str = <<-EOF
    <id>#{id}</id>
    <name><![CDATA[#{name}]]></name>
  EOF
  str + (children ? "<subcategories>#{children}</subcategories>" : "")
}

CATEGORY_TAG = Proc.new { |root, category|
  root ||= 'result'
  category ||= CATEGORY.call
  
  <<-EOF
    <#{root}>
      #{category}
    </#{root}>
  EOF
}

RESULT = Proc.new { |categories|
  categories ||= (0..10).map { CATEGORY_TAG.call(nil, nil, ((0..10).map { CATEGORY_TAG.call('subcategory') }.join("\n"))) }.join("\n")
  <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <rsp stat="ok">
      <result_set>
        #{categories}
      </result_set>
    </rsp>
  EOF
}

describe Scribd::Category do
  before do
    Scribd::API.key = "test key"
    Scribd::API.secret = "secret"
  end
  
  describe "#initialize" do
    context "without XML" do
      subject { Scribd::Category.new :name => 'foo' }
      it { expect { subject }.should raise_error }
    end
    
    context "with XML" do
      let(:response) { CATEGORY_TAG.call(nil, CATEGORY.call('12', 'test')) }
      subject { Scribd::Category.new(:xml => Nokogiri::XML(response).root) }
      it { should be_saved }
      it { should be_created }
      
      its(:scribd_id) { should eql('12') }
      its(:name) { should eql('test') }
    end
    
    context "with XML and nodes" do
      let(:response) { CATEGORY_TAG.call(nil, CATEGORY.call(nil, nil, CATEGORY_TAG.call('subcategory', CATEGORY.call('100')))) }
      subject { Scribd::Category.new(:xml => Nokogiri::XML(response).root) }
      before { Scribd::API.should_not_receive(:post) }

      its(:children) { should be_kind_of(Array) }
      its("children.first") { should be_kind_of(Scribd::Category) }
      its("children.first.scribd_id") { should == '100' }
      its("children.first.name") { should == 'Test Category 100' }
      its("children.first.parent") { should == subject }
    end
  end
    
  describe "#children" do
    context "when the category has preloaded children" do
      let(:preloaded) { Scribd::Category.new(:xml => Nokogiri::XML(CATEGORY_TAG.call(nil, CATEGORY.call(nil, nil, CATEGORY_TAG.call('subcategory')))).root) }
      
      before { Scribd::API.should_not_receive(:post) }
      
      subject { preloaded.children }
      
      it { should be_kind_of Array }
    end

    context "when the category has not preloaded children" do
      let(:not_preloaded) { Scribd::Category.new(:xml => Nokogiri::XML(CATEGORY_TAG.call(nil, CATEGORY.call('3'))).root) }
      let(:response) { RESULT.call(CATEGORY_TAG.call) }
      
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "category_id=3&method=docs.getCategories&api_key=test%20key&api_sig=3778cbd34ef01a487a78a941344ee35a")
          .to_return(:body => response)
      end

      subject { not_preloaded.children }

      it { should be_kind_of Array }
    end
  end
  
  describe "#browse" do
    let(:response) { <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <rsp stat="ok">
          <result_set totalResultsAvailable="922" totalResultsReturned="2" firstResultPosition="1" list="true">
            <result>
              <title>&lt;![CDATA[Ruby on Java]]&gt;</title>
              <description>&lt;![CDATA[Ruby On Java, Barcamp, Washington DC]]&gt;</description>
              <access_key>key-t3q5qujoj525yun8gf7</access_key>
              <doc_id>244565</doc_id>
              <page_count>10</page_count>
              <download_formats></download_formats>
            </result>
            <result>
              <title>&lt;![CDATA[Ruby on Java Part II]]&gt;</title>
              <description>&lt;![CDATA[Ruby On Java Part II, Barcamp, Washington DC]]&gt;</description>
              <access_key>key-2b3udhalycthsm91d1ps</access_key>
              <doc_id>244567</doc_id>
              <page_count>12</page_count>
              <download_formats>pdf,txt</download_formats>
            </result>
          </result_set>
        </rsp>
      EOF
    }
    
    let(:category) { Scribd::Category.new(:xml => Nokogiri::XML(CATEGORY_TAG.call(nil, CATEGORY.call('12', 'test'))).root) }
    
    context "without options" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "category_id=12&method=docs.browse&api_key=test%20key&api_sig=45d29e5f044b89e8db56d0589303601b")
          .to_return(:body => response)
      end
      
      subject { category.browse }
      it { should be_kind_of Array }
      its(:first) { should be_kind_of Scribd::Document }
    end
    
    context "with options" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "foo=bar&category_id=12&method=docs.browse&api_key=test%20key&api_sig=4d0bbad2c9eb8e1bc0baaa1c699372e9")
          .to_return(:body => response)
      end
      
      subject { category.browse(:foo => 'bar') }
      it { should be_kind_of Array }
      its(:first) { should be_kind_of Scribd::Document }
    end
  end
  
  describe ".all" do
    let(:response) { RESULT.call(CATEGORY_TAG.call) }
    
    context "without parameters" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "method=docs.getCategories&api_key=test%20key&api_sig=0963d1c1cf07ae8d747afaa67b73e968")
          .to_return(:body => response)
      end
      
      subject { Scribd::Category.all }
      
      it { should be_kind_of Array }
      it { should have(1).category }
      its(:first) { should be_kind_of Scribd::Category }
    end
    
    context "with parameter all" do
      before do
        stub_request(:post, "http://api.scribd.com/api")
               .with(:body => "with_subcategories=true&method=docs.getCategories&api_key=test%20key&api_sig=7927bc08fef611bd6ffab5847abbd598")
          .to_return(:body => response)
      end
      
      subject { Scribd::Category.all true }
      
      it { should be_kind_of Array }
      it { should have(1).category }
      its(:first) { should be_kind_of Scribd::Category }
    end
  end
end
