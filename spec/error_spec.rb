require 'spec_helper'

describe Scribd::ResponseError do
  subject { Scribd::ResponseError.new(123) }
  its(:code) { should == 123 }
end
