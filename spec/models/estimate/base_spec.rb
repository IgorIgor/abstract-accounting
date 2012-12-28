require "rspec"

describe Estimate::Base do
  it "should have next behavior" do
    Estimate::Base.abstract_class.should be_true
    Estimate::Base.table_name_prefix.should eq("estimate_")
  end
end
