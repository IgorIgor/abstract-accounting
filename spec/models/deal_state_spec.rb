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
    DealState.create!(deal_id: create(:deal).id)
  end

  it "should have next behaviour" do
    should validate_uniqueness_of :deal_id
    should belong_to :deal
  end

  describe "#in_work?" do
    it "should be in work if close is not set" do
      DealState.first.in_work?.should be_true
    end

    it "should not be in work if close is set" do
      state = DealState.first
      state.closed = Date.today
      state.save!
      DealState.first.in_work?.should be_false
    end
  end

  describe "#closed?" do
    it "should be closed if close is set" do
      state = DealState.first
      state.closed = Date.today
      state.save!
      DealState.first.closed?.should be_true
    end

    it "should not be closed if close is not set" do
      state = DealState.first
      state.closed = nil
      state.save!
      DealState.first.closed?.should be_false
    end
  end

  describe "#save" do
    it "should set open field to today" do
      DealState.create!(deal_id: create(:deal).id).opened.should eq(Date.today)
    end
  end

  describe "#close" do
    it "should set close to today" do
      DealState.create!(deal_id: create(:deal).id).close.should be_true
      DealState.last.closed.should eq(Date.today)
    end

    it "should return false if already closed" do
      DealState.create!(deal_id: create(:deal).id).close.should be_true
      DealState.last.close.should be_false
    end
  end
end
