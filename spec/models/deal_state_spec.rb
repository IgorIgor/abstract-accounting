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
    should allow_mass_assignment_of :deal_id
    should_not allow_mass_assignment_of :opened
    should_not allow_mass_assignment_of :closed
    should_not allow_mass_assignment_of :reversed
    should have_many DealState.versions_association_name

    should allow_value(DealState::UNKNOWN).for(:state)
    should allow_value(DealState::INWORK).for(:state)
    should allow_value(DealState::CANCELED).for(:state)
    should allow_value(DealState::APPLIED).for(:state)
    should allow_value(DealState::REVERSED).for(:state)

    DealState.new.state.should eq(DealState::UNKNOWN)
    DealState.first.state.should eq(DealState::INWORK)
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

    it "should not be closed if reversed" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.closed = Date.today
      state.reversed = Date.today
      state.save!
      state.closed?.should be_false
    end
  end

  describe "#reversed?" do
    it "should not be reversed if opened is not set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.reversed = Date.today
      state.should_not be_reversed
    end

    it "should not be reversed if closed is not set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.reversed = Date.today
      state.opened = Date.today
      state.should_not be_reversed
    end

    it "should not be reversed if reversed is not set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.closed = Date.today
      state.opened = Date.today
      state.should_not be_reversed
    end

    it "should be reversed if all are set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.closed = Date.today
      state.opened = Date.today
      state.reversed = Date.today
      state.should be_reversed
    end
  end

  describe "#unknown?" do
    it "should not be unknown if opened is set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.opened = Date.today
      state.should_not be_unknown
    end

    it "should not be unknown if closed is set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.closed = Date.today
      state.should_not be_unknown
    end

    it "should not be unknown if reversed is set" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.reversed = Date.today
      state.should_not be_unknown
    end

    it "should be unknown if all are not set" do
      state = DealState.new(deal_id: create(:deal).id)
      state.should be_unknown
    end
  end

  describe "#save" do
    it "should set open field to today" do
      DealState.create!(deal_id: create(:deal).id).opened.should eq(Date.today)
    end
  end

  describe "#apply" do
    it "should set close to today" do
      DealState.create!(deal_id: create(:deal).id).apply.should be_true
      DealState.last.closed.should eq(Date.today)
    end

    it "should return false if already applied" do
      DealState.create!(deal_id: create(:deal).id).apply.should be_true
      DealState.last.apply.should be_false
    end

    it "should change state to APPLIED" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.state.should eq(DealState::APPLIED)
    end
  end

  describe "#cancel" do
    it "should set close to today" do
      DealState.create!(deal_id: create(:deal).id).cancel.should be_true
      DealState.last.closed.should eq(Date.today)
    end

    it "should return false if already CANCELED" do
      DealState.create!(deal_id: create(:deal).id).cancel.should be_true
      DealState.last.cancel.should be_false
    end

    it "should change state to CANCELED" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.cancel.should be_true
      state.state.should eq(DealState::CANCELED)
    end
  end

  describe "#reverse" do
    it "should set reversed to today" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.reverse.should be_true
      state.reversed.should eq(Date.today)
    end

    it "should return false if already REVERSED" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.reverse.should be_true
      state.reverse.should be_false
    end

    it "should change state to REVERSED" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.reverse.should be_true
      state.state.should eq(DealState::REVERSED)
    end
  end

  describe "#can_apply?" do
    it "should be appliable if state is inwork" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.should be_can_apply
    end

    it "should return false if in closed state" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.should_not be_can_apply
    end
  end

  describe "#can_cancel?" do
    it "should be cancelable if state is inwork" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.should be_can_cancel
    end

    it "should return false if in closed state" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.should_not be_can_cancel
    end
  end

  describe "#can_reverse?" do
    it "should be reversable if state is applied" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.apply.should be_true
      state.should be_can_reverse
    end

    it "should return false if in cancelled state" do
      state = DealState.create!(deal_id: create(:deal).id)
      state.cancel.should be_true
      state.should_not be_can_reverse
    end
  end
end
