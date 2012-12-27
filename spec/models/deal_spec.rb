# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Deal do
  it "should have next behaviour" do
    create(:deal)
    should validate_presence_of :tag
    should validate_presence_of :rate
    should validate_presence_of :entity_id
    should validate_presence_of :give
    should validate_presence_of :take
    should validate_uniqueness_of(:tag).scoped_to(:entity_id, :entity_type)
    should belong_to :entity
    should have_many(:states)
    should have_many(:balances)
    should have_many(:rules)
    should have_many(:terms)
    should have_one(:give).class_name(Term).conditions(:side => false)
    should have_one(:take).class_name(Term).conditions(:side => true)
    should have_many Deal.versions_association_name
    should have_one :deal_state
    should have_one :allocation
    should have_one :waybill

    should delegate_method(:can_apply?).to(:deal_state)
    should delegate_method(:can_cancel?).to(:deal_state)
    should delegate_method(:can_reverse?).to(:deal_state)

    should delegate_method(:apply).to(:deal_state)
    should delegate_method(:cancel).to(:deal_state)
    should delegate_method(:reverse).to(:deal_state)

    should delegate_method(:in_work?).to(:deal_state)

    deal_has_states
    deal_has_balances
  end

  def deal_has_states
    s = create(:state)
    s.should eq(s.deal.state(s.start)),
             "State from first deal is not equal saved state"
    s.deal.state(DateTime.now - 1).should be_nil, "State is not nil"
  end

  def deal_has_balances
    b = create(:balance)
    b.should eq(b.deal.balance),
             "Balance from first deal is not equal to saved balance"
  end

  it "should sort deals" do
    10.times { create(:deal) }

    ds = Deal.sort_by_name("asc").all
    query = "case entity_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
    ds_test = Deal.joins{entity(Entity).outer}.joins{entity(LegalEntity).outer}.
        order("#{query}").all
    ds.should eq(ds_test)
    ds = Deal.sort_by_name("desc").all
    ds_test = Deal.joins{entity(Entity).outer}.joins{entity(LegalEntity).outer}.
        order("#{query} DESC").all
    ds.should eq(ds_test)

    ds = Deal.sort_by_give("asc").all
    query = "case resource_type
                  when 'Asset' then assets.tag
                  when 'Money' then money.alpha_code
             end"
    ds_test = Deal.joins{give.resource(Asset).outer}.joins{give.resource(Money).outer}.
        order("#{query}").all
    ds.should eq(ds_test)
    ds = Deal.sort_by_give("desc").all
    ds_test = Deal.joins{give.resource(Asset).outer}.joins{give.resource(Money).outer}.
        order("#{query} DESC").all
    ds.should eq(ds_test)

    ds = Deal.sort_by_take("asc").all
    query = "case resource_type
                  when 'Asset' then assets.tag
                  when 'Money' then money.alpha_code
             end"
    ds_test = Deal.joins{take.resource(Asset).outer}.joins{take.resource(Money).outer}.
        order("#{query}").all
    ds.should eq(ds_test)
    ds = Deal.sort_by_take("desc").all
    ds_test = Deal.joins{take.resource(Asset).outer}.joins{take.resource(Money).outer}.
        order("#{query} DESC").all
    ds.should eq(ds_test)
  end

  it "create limit with deal" do
    deal = create(:deal)
    deal.limit.should_not be_nil
    deal.limit.amount.should eq(0)
    deal.limit.side.should eq(0)
  end
end
