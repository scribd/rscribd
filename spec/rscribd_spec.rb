require 'spec_helper'

describe Symbol do
  subject { :symbol }
  its(:to_proc) { should be_kind_of(Proc) }
end

describe Hash do
  subject { { :a => :b, 1 => 3 } }
  its(:stringify_keys) { should == { 'a' => :b, '1' => 3 } }
end

describe Array do
  subject { [ [ 1, 2], [3, 4] ] }
  its(:to_hsh) { should == { 1 => 2, 3 => 4 } }
end
