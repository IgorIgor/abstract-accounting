# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Distribution do
  before(:all) do
    create(:chart)
    @wb = build(:waybill)
    @wb.add_item('roof', 'm2', 500, 10.0)
    @wb.add_item('nails', 'pcs', 1200, 1.0)
    @wb.add_item('nails', 'kg', 10, 150.0)
    @wb.save!
    @wb.apply
  end

  it 'should have next behaviour' do
    should validate_presence_of :foreman
    should validate_presence_of :storekeeper
    should validate_presence_of :foreman_place
    should validate_presence_of :storekeeper_place
    should validate_presence_of :created
    should validate_presence_of :state
    should belong_to :deal
    should belong_to :foreman
    should belong_to :storekeeper
    should belong_to(:foreman_place).class_name(Place)
    should belong_to(:storekeeper_place).class_name(Place)
    should have_many Distribution.versions_association_name
  end

  it 'should create items' do
    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('nails', 'pcs', 500)
    db.add_item('nails', 'kg', 2)
    db.items.count.should eq(2)
    lambda { db.save } .should change(Distribution, :count).by(1)
    db.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    db.items[0].amount.should eq(500)
    db.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    db.items[1].amount.should eq(2)

    db = Distribution.find(db)
    db.items.count.should eq(2)
    db.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    db.items[0].amount.should eq(500)
    db.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    db.items[1].amount.should eq(2)
  end

  it 'should create deals' do
    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('roof', 'm2', 200)
    lambda { db.save } .should change(Deal, :count).by(2)

    deal = Deal.find(db.deal)
    deal.entity.should eq(db.storekeeper)
    deal.isOffBalance.should be_true

    deal = db.items.first.warehouse_deal(nil, db.storekeeper_place, db.storekeeper)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    deal = db.items.first.warehouse_deal(nil, db.foreman_place, db.foreman)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: @wb.distributor,
                         distributor_place: @wb.distributor_place,
                         storekeeper: @wb.storekeeper,
                         storekeeper_place: @wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('hammer', 'th', 500, 100.0)
    lambda { wb.save; wb.apply } .should change(Deal, :count).by(3)

    db = build(:distribution, storekeeper: db.storekeeper,
                              storekeeper_place: db.storekeeper_place)
    db.add_item('roof', 'm2', 20)
    db.add_item('nails', 'pcs', 10)
    db.add_item('hammer', 'th', 50)
    lambda { db.save } .should change(Deal, :count).by(4)

    deal = Deal.find(db.deal)
    deal.entity.should eq(db.storekeeper)
    deal.isOffBalance.should be_true

    db.items.each { |i|
      deal = i.warehouse_deal(nil, db.storekeeper_place, db.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, db.foreman_place, db.foreman)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    }
  end

  it 'should create rules' do
    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('roof', 'm2', 200)
    lambda { db.save } .should change(Rule, :count).by(1)

    rule = db.deal.rules.first
    rule.rate.should eq(200)
    db.items.first.warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper).should eq(rule.from)
    db.items.first.warehouse_deal(nil, db.foreman_place,
      db.foreman).should eq(rule.to)

    db = build(:distribution, storekeeper: db.storekeeper,
                              storekeeper_place: db.storekeeper_place)
    db.add_item('roof', 'm2', 150)
    db.add_item('nails', 'pcs', 300)
    lambda { db.save } .should change(Rule, :count).by(2)

    rule = db.deal.rules[0]
    rule.rate.should eq(150)
    db.items[0].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper).should eq(rule.from)
    db.items[0].warehouse_deal(nil, db.foreman_place,
      db.foreman).should eq(rule.to)

    rule = db.deal.rules[1]
    rule.rate.should eq(300)
    db.items[1].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper).should eq(rule.from)
    db.items[1].warehouse_deal(nil, db.foreman_place,
      db.foreman).should eq(rule.to)
  end

  it 'should change state' do
    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('roof', 'm2', 5)
    db.state.should eq(Distribution::UNKNOWN)

    db.cancel.should be_false

    db.save!
    db.state.should eq(Distribution::INWORK)

    db = Distribution.find(db)
    db.cancel.should be_true
    db.state.should eq(Distribution::CANCELED)

    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('roof', 'm2', 1)
    db.save!
    db.apply.should be_true
    db.state.should eq(Distribution::APPLIED)
  end

  it 'should create facts by rules after apply' do
    db = build(:distribution, storekeeper: @wb.storekeeper,
                              storekeeper_place: @wb.storekeeper_place)
    db.add_item('roof', 'm2', 5)
    db.add_item('nails', 'pcs', 10)

    roof_deal = db.items[0].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper)
    nails_deal = db.items[1].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper)

    roof_deal.state.amount.should eq(599.0)
    nails_deal.state.amount.should eq(1200.0)

    db.save.should be_true
    lambda { db.apply } .should change(Fact, :count).by(3)

    roof_deal.state.amount.should eq(594.0)
    nails_deal.state.amount.should eq(1190.0)
  end
end

describe DistributionItemsValidator do
  it 'should not validate' do
    create(:chart)
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 500, 10.0)
    wb.add_item('nails', 'pcs', 1200, 1.0)
    wb.save!
    wb.apply

    db = build(:distribution, storekeeper: wb.storekeeper,
                              storekeeper_place: wb.storekeeper_place)
    db.add_item('', 'm2', 1)
    db.should be_invalid
    db.items.clear
    db.add_item('roof', 'm2', 0)
    db.should be_invalid
    db.items.clear
    db.add_item('roof', 'm2', 500)
    db.add_item('nails', 'pcs', 1201)
    db.should be_invalid
    db.items.clear
    db.add_item('roof', 'm2', 300)
    db.save!

    db2 = build(:distribution, storekeeper: wb.storekeeper,
                               storekeeper_place: wb.storekeeper_place)
    db2.add_item('roof', 'm2', 201)
    db2.should be_invalid

    db.cancel
    db.add_item('roof', 'm2', 201)
    db.should be_valid
  end
end
