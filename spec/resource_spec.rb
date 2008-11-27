old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Scribd::Resource do
  describe "initialized from attributes" do
    before :each do
      @resource = Scribd::Resource.new
    end
    
    it "should be unsaved" do
      @resource.should_not be_saved
    end
    
    it "should be uncreated" do
      @resource.should_not be_created
    end
  end
  
  describe ".save" do
    it "should create a new instance and save it and return it" do
      resource = mock('Scribd::Resource resource')
      resource.should_receive(:save).once
      Scribd::Resource.stub!(:new).and_return(resource)
      Scribd::Resource.create.should eql(resource)
    end
  end
  
  it "should not implement save" do
    lambda { Scribd::Resource.new.save }.should raise_error(NotImplementedError)
  end
  
  it "should not implement find" do
    lambda { Scribd::Resource.find(1) }.should raise_error(NotImplementedError)
  end
  
  it "should not implement destroy" do
    lambda { Scribd::Resource.new.destroy }.should raise_error(NotImplementedError)
  end
  
  it "should implement saved?" do
    resource = Scribd::Resource.new
    resource.instance_variable_set(:@saved, true)
    resource.should be_saved
  end
  
  it "should implement created?" do
    resource = Scribd::Resource.new
    resource.instance_variable_set(:@created, true)
    resource.should be_created
  end
  
  describe "with attributes" do
    before :each do
      @resource = Scribd::Resource.new
      @resource.instance_variable_set(:@attributes, { :access => 'private', :owner => 'me!', :warp => 9 })
    end
    
    describe "read_attribute method" do
      it "should raise ArgumentError if the attribute name cannot be converted to a symbol" do
        attr_name = mock('attr_name')
        lambda { @resource.read_attribute attr_name }.should raise_error(ArgumentError)
      end
      
      it "should return the attribute value for valid attributes" do
        @resource.read_attribute(:access).should eql('private')
      end
    end
    
    describe "read_attributes method" do
      it "should raise ArgumentError if a list is not provided" do
        lambda { @resource.read_attributes nil }.should raise_error(ArgumentError)
      end
      
      it "should raise ArgumentError if any attribute name cannot be converted to a symbol" do
        attr_name = mock('attr_name')
        lambda { @resource.read_attributes [ attr_name, :test ] }.should raise_error(ArgumentError)
      end
      
      it "should return the values of the given attribute names" do
        @resource.read_attributes([ :access, :owner ]).should == { :access => 'private', :owner => 'me!' }
      end
      
      it "should convert all keys to symbols" do
        @resource.read_attributes([ 'access' ]).should == { :access => 'private' }
      end
    end
    
    describe "write_attributes method" do
      it "should raise ArgumentError if a hash is not provided" do
        lambda { @resource.write_attributes nil }.should raise_error(ArgumentError)
      end
      
      it "should raise ArgumentError if any attribute name cannot be converted to a symbol" do
        attr_name = mock('attr_name')
        lambda { @resource.write_attributes attr_name => 1, :test => 2 }.should raise_error(ArgumentError)
      end
      
      it "should set the values of the given attribute names" do
        @resource.write_attributes(:access => 'public', :owner => 'you')
        @resource.access.should eql('public')
        @resource.owner.should eql('you')
      end
      
      it "should convert all keys to symbols" do
        @resource.write_attributes('access' => 'public')
        @resource.access.should eql('public')
      end
      
      it "should not call save" do
        @resource.should_not_receive(:save)
        @resource.write_attributes 'access' => 'public'
      end
    end
    
    it "should create getters for each attribute" do
      lambda { @resource.warp }.should_not raise_error(NoMethodError)
    end
    
    it "should create setters for each attribute" do
      lambda { @resource.warp = 5 }.should_not raise_error(NoMethodError)
    end
  end
end

Dir.chdir old_dir
