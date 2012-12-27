# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

class TestStatable < ActiveRecord::Base
  has_no_table
  column :deal_id, :integer

  belongs_to :deal

  attr_reader :apply_called, :cancel_called, :reverse_called

  after_initialize :my_init

  include Helpers::Statable
  act_as_statable

  after_apply :do_apply
  after_cancel :do_cancel
  after_reverse :do_reverse

  def save
    run_callbacks(:save) { true }
  end

  private
    def my_init
      @apply_called = false
      @cancel_called = false
      @reverse_called = false
      self.deal_id = Deal.last.id
    end

    def do_apply
      FactoryGirl.create(:fact, amount: 1.0, from: nil, to: Deal.last)
      @apply_called = true
    end

    def do_cancel
      @cancel_called = true
    end

    def do_reverse
      FactoryGirl.create(:fact, amount: -1.0, from: nil, to: Deal.last)
      @reverse_called = true
    end
end

describe Helpers::Statable do
  before :all do
    create(:deal)
  end

  it "should add state after save" do
    lambda { TestStatable.new.save }.should change(DealState, :count).by(1)
    DealState.last.deal_id.should eq(Deal.last.id)
    DealState.last.opened.should eq(Date.today)
    DealState.last.state.should eq(Helpers::Statable::INWORK)
  end

  it "should change state from inwork to apply after apply" do
    obj = TestStatable.new
    obj.apply.should be_true
    obj.apply_called.should be_true
    obj.state.should eq(Helpers::Statable::APPLIED)
    obj.should_not be_can_apply
    obj.should_not be_can_cancel
    obj.should be_can_reverse
  end

  it "should change state from applied to reversed after reverse" do
    obj = TestStatable.new
    obj.reverse.should be_true
    obj.reverse_called.should be_true
    obj.state.should eq(Helpers::Statable::REVERSED)
    obj.should_not be_can_apply
    obj.should_not be_can_cancel
    obj.should_not be_can_reverse
  end

  it "should change state from inwork to canceled after cancel" do
    create(:deal)
    obj = TestStatable.new
    obj.save
    obj.cancel.should be_true
    obj.cancel_called.should be_true
    obj.state.should eq(Helpers::Statable::CANCELED)
    obj.should_not be_can_apply
    obj.should_not be_can_cancel
    obj.should_not be_can_reverse
  end

  describe "#search" do
    it "should return scoped if states is empty" do
      TestStatable.search(states: []).joins_values.should be_empty
    end

    it "should return scoped if all states are selected" do
      TestStatable.search(states: [Helpers::Statable::INWORK, Helpers::Statable::APPLIED,
                                   Helpers::Statable::CANCELED, Helpers::Statable::REVERSED]).
          joins_values.should be_empty
    end

    it "should joins deal_state and setup where for inwork state" do
      test = TestStatable.search(states: [Helpers::Statable::INWORK])
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(Squeel::DSL.eval {
        (deal.deal_state.state == Helpers::Statable::INWORK)
      })
    end

    it "should joins deal_state and setup where for apply state" do
      test = TestStatable.search(states: [Helpers::Statable::APPLIED])
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(Squeel::DSL.eval {
        (deal.deal_state.state == Helpers::Statable::APPLIED)
      })
    end

    it "should joins deal_state and setup where for cancel state" do
      test = TestStatable.search(states: [Helpers::Statable::CANCELED])
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(Squeel::DSL.eval {
        (deal.deal_state.state == Helpers::Statable::CANCELED)
      })
    end

    it "should joins deal_state and setup where for reverse state" do
      test = TestStatable.search(states: [Helpers::Statable::REVERSED])
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(Squeel::DSL.eval {
        (deal.deal_state.state == Helpers::Statable::REVERSED)
      })
    end

    it "should joins deal_state and setup where for multiple states"do
      test = TestStatable.search(states: [Helpers::Statable::INWORK,
                                          Helpers::Statable::APPLIED])
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(
             Squeel::DSL.eval {
               (deal.deal_state.state == Helpers::Statable::INWORK) |
                   (deal.deal_state.state == Helpers::Statable::APPLIED)})
    end
  end

  describe "#sort" do
    it "should joins deal_state" do
      test = TestStatable.sort(field: :state, type: "asc")
      test.joins_values.count.should eq(1)
      test.joins_values[0].should eql(Squeel::DSL.eval{deal.deal_state})
    end

    it "should add order state" do
      test = TestStatable.sort(field: :state, type: "asc")
      test.order_values.count.should eq(1)
      dsl = Squeel::DSL.eval{deal.deal_state.state.asc}
      test.order_values[0].direction.should eql(dsl.direction)
      test = TestStatable.sort(field: :state, type: "desc")
      test.order_values.count.should eq(1)
      dsl = Squeel::DSL.eval{deal.deal_state.state.desc}
      test.order_values[0].direction.should eql(dsl.direction)
    end
  end
end
