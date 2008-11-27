old_dir = Dir.getwd
Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rscribd'

describe Scribd::ResponseError do
  it "should set the code attribute on initialization" do
    error = Scribd::ResponseError.new(123)
    error.code.should eql(123)
  end
end

Dir.chdir old_dir
