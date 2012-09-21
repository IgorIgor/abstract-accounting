# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

class TestStatable
  attr_reader :apply_called, :cancel_called, :reverse_called

  def initialize
    @apply_called = false
    @cancel_called = false
    @reverse_called = false
  end

  class << self
    def after_save(method)
      self.after_save_i = method
    end
  end

  class_attribute :after_save_i

  include Helpers::Statable
  act_as_statable

  after_apply :do_apply
  after_cancel :do_cancel
  after_reverse :do_reverse

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

  def deal
    Deal.last
  end

  def deal_id
    Deal.last.id
  end

  def save
    self.send(TestStatable.after_save_i.to_s)
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
  end

  it "should be in work after first save" do
    obj = TestStatable.new
    obj.state.should eq(Helpers::Statable::INWORK)
    obj.should be_can_apply
    obj.should be_can_cancel
    obj.should_not be_can_reverse
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
end
