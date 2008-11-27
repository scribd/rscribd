old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Symbol do
  it "should define a to_proc method" do
    Symbol.instance_methods.map { |meth| meth.to_sym }.should include(:to_proc)
  end
  
  it "... that returns a Proc" do
    :to_s.to_proc.should be_kind_of(Proc)
  end
end

describe Hash do
  it "should define a stringify_keys method" do
    Hash.instance_methods.map(&:to_sym).should include(:stringify_keys)
  end
  
  it "... that converts hash keys into strings" do
    { :a => :b, 1 => 3 }.stringify_keys.should == { 'a' => :b, '1' => 3 }
  end
end

describe Array do
  it "should define a to_hsh method" do
    Array.instance_methods.map(&:to_sym).should include(:to_hsh)
  end
  
  it "... that converts nested arrays into a hash" do
    [ [ 1, 2], [3, 4] ].to_hsh.should == { 1 => 2, 3 => 4 }
  end
end

Dir.chdir old_dir
