require 'spec_helper'

describe Scribd::ResponseError do
  it "should set the code attribute on initialization" do
    error = Scribd::ResponseError.new(123)
    error.code.should eql(123)
  end
end
