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
  subject { Scribd::Category.new(:xml => REXML::Document.new(CATEGORY_TAG.call(nil, CATEGORY.call('12', 'test'))).root) }
  
  describe "#initialize" do
    it "should raise an error if initialized without XML" do
      lambda { Scribd::Category.new :name => 'foo' }.should raise_error
    end
    
    context "attributes" do
      its(:id) { should eql('12') }
      its(:name) { should eql('test') }
    end
    
    it "should populate children that link back to their parents" do
      response = CATEGORY_TAG.call(nil, CATEGORY.call(nil, nil, CATEGORY_TAG.call('subcategory', CATEGORY.call('100'))))
      
      category = Scribd::Category.new(:xml => REXML::Document.new(response).root)
      Scribd::API.instance.should_not_receive(:send_request) # not really being tested here, but we should make sure we don't actually make remote requests
      category.children.should be_kind_of(Array)
      category.children.first.should be_kind_of(Scribd::Category)
      category.children.first.id.should eql('100')
      category.children.first.name.should eql('Test Category 100')
      category.children.first.children_preloaded?.should be_false
      category.children.first.parent.should eql(category)
    end
    
    it { should be_saved }
    it { should be_created }
  end
  
  describe "#children_preloaded?" do
    it "should be true for categories initialized with children" do
      response = CATEGORY_TAG.call(nil, CATEGORY.call(nil, nil, CATEGORY_TAG.call('subcategory')))
      Scribd::Category.new(:xml => REXML::Document.new(response).root).children_preloaded?.should be_true
    end
    
    it "should be false for categories initialized without children" do
      Scribd::Category.new(:xml => REXML::Document.new(CATEGORY_TAG.call).root).children_preloaded?.should be_false
    end
  end
  
  describe :all do
    before :each do
      @response = REXML::Document.new(RESULT.call).root
    end
    
    it "should send an API request to docs.getCategories" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getCategories').and_return(@response)
      Scribd::Category.all
    end
    
    it "should set with_subcategories if include_children is true" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getCategories', :with_subcategories => true).and_return(@response)
      Scribd::Category.all(true)
    end
    
    it "should return an array of categories" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      categories = Scribd::Category.all
      categories.should be_kind_of(Array)
      categories.first.should be_kind_of(Scribd::Category)
      categories.last.should be_kind_of(Scribd::Category)
    end
  end
  
  describe "#children" do
    before :each do
      xml = REXML::Document.new(CATEGORY_TAG.call(nil, CATEGORY.call(nil, nil, CATEGORY_TAG.call('subcategory')))).root
      @preloaded = Scribd::Category.new(:xml => xml)
      
      xml = REXML::Document.new(CATEGORY_TAG.call(nil, CATEGORY.call('3'))).root
      @not_preloaded = Scribd::Category.new(:xml => xml)
      
      @response = REXML::Document.new(RESULT.call(CATEGORY_TAG.call)).root
    end
    
    it "should not make a network call if the category has preloaded children" do
      Scribd::API.instance.should_not_receive(:send_request)
      @preloaded.children
    end
    
    it "should otherwise make an API call to docs.getCategories" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.getCategories', :category_id => '3').and_return(@response)
      @not_preloaded.children
    end
    
    it "should return an array of child categories" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      cats = @not_preloaded.children
      cats.should be_kind_of(Array)
      cats.first.should be_kind_of(Scribd::Category)
    end
  end
  
  describe "#browse" do
    before :each do
      @response = REXML::Document.new(<<-EOF
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
      ).root
    end
    
    it "should make an API call to docs.browse" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.browse', :category_id => '12').and_return(@response)
      subject.browse
    end
    
    it "should pass options to the API call" do
      Scribd::API.instance.should_receive(:send_request).once.with('docs.browse', :category_id => '12', :foo => 'bar').and_return(@response)
      subject.browse(:foo => 'bar')
    end
    
    it "should return an array of Documents" do
      Scribd::API.instance.stub!(:send_request).and_return(@response)
      docs = subject.browse
      docs.should be_kind_of(Array)
      docs.each do |doc|
        doc.should be_kind_of(Scribd::Document)
      end
    end
  end
end
