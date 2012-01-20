require 'spec_helper'

describe Scribd::Resource do
  let(:resource) { Scribd::Resource.new :access => 'private', :owner => 'me!', :warp => 9 }
  
  it { should_not be_saved }
  it { should_not be_created }
  
  describe "#save" do
    it { expect { subject.save }.to raise_error(NotImplementedError) }
  end
  
  describe "#destroy" do
    it { expect { subject.destroy }.to raise_error(NotImplementedError) }
  end
  
  describe ".save" do
    it "should create a new instance and save it and return it" do
      resource = double('Scribd::Resource resource')
      resource.should_receive(:save).once
      Scribd::Resource.stub!(:new).and_return(resource)
      Scribd::Resource.create.should eql(resource)
    end
  end
  
  describe ".find" do
    it { expect { Scribd::Resource.find(1) }.to raise_error(NotImplementedError) }
  end
  
  describe "#read_attribute" do
    subject { resource.read_attribute(argument) }
    
    context "when the argument responds to :to_sym" do
      let(:argument) { :access }
      it { should == "private" }
    end
  end
    
  describe "#method_missing" do
    context "when the attribute exists" do
      it { expect { resource.warp = 10 }.to change(resource, :warp).from(9).to(10) }
    end
    
    context "when the attribute doesn't exist" do
      it { expect { resource.troll = 10 }.to change(resource, :troll).from(nil).to(10) }
    end
  end
  
  context "when the type of the element is defined" do
    context "as integer" do
      subject { Scribd::Resource.new(:xml => Nokogiri::XML("<rsp stat='ok'><field type='integer'>     10    </field></rsp>").root) }
      its(:field) { should == 10 }
      its(:field) { should be_kind_of Fixnum }
    end
    
    context "as float" do
      subject { Scribd::Resource.new(:xml => Nokogiri::XML("<rsp stat='ok'><field type='float'>     10    </field></rsp>").root) }
      its(:field) { should == 10.0 }
      its(:field) { should be_kind_of Float }
    end
    
    context "as symbol" do
      subject { Scribd::Resource.new(:xml => Nokogiri::XML("<rsp stat='ok'><field type='symbol'>    scribd    </field></rsp>").root) }
      its(:field) { should == :scribd }
      its(:field) { should be_kind_of Symbol }
    end
  end
end
