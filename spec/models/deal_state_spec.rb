# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe DealState do
  before :all do
    d = DealState.new(open: Date.today)
    d.deal = create(:deal)
    d.save!
  end

  it "should have next behaviour" do
    should validate_presence_of :open
    should validate_uniqueness_of :deal_id
    should belong_to :deal
  end

  describe "#in_work?" do
    it "should be in work if close is not set" do
      DealState.first.in_work?.should be_true
    end

    it "should not be in work if close is set" do
      DealState.first.update_attributes(close: Date.today)
      DealState.first.in_work?.should be_false
    end
  end

  describe "#closed?" do
    it "should be closed if close is set" do
      DealState.first.update_attributes(close: Date.today)
      DealState.first.closed?.should be_true
    end

    it "should not be closed if close is not set" do
      DealState.first.update_attributes(close: nil)
      DealState.first.closed?.should be_false
    end
  end
end
