# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Allocation do
  before(:all) do
    create(:chart)
    @wb = build(:waybill)
    @wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    @wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    @wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    @wb.save!
    @wb.apply
  end

  it 'should have next behaviour' do
    should validate_presence_of :foreman
    should validate_presence_of :foreman_place
    should validate_presence_of :created
    should validate_presence_of :state
    should validate_presence_of :storekeeper
    should validate_presence_of :storekeeper_place
    should belong_to :deal
    should have_many Allocation.versions_association_name
    should have_many :comments
  end

  it "should not create items by empty fields" do
    db = Allocation.new(created: Date.today,
                        foreman_type: Entity.name,
                        storekeeper_id: @wb.storekeeper.id,
                        storekeeper_type: @wb.storekeeper.class.name,
                        storekeeper_place_id: @wb.storekeeper_place.id)
    db.storekeeper.should eq(@wb.storekeeper)
    db.storekeeper_place.should eq(@wb.storekeeper_place)
    db.foreman.should be_nil
  end

  it 'should create items' do
    db = Allocation.new(created: Date.today,
                        foreman_id: create(:entity).id, foreman_type: Entity.name,
                        storekeeper_id: @wb.storekeeper.id,
                        storekeeper_type: @wb.storekeeper.class.name,
                        foreman_place_id: @wb.storekeeper_place.id,
                        storekeeper_place_id: @wb.storekeeper_place.id)
    db.storekeeper.should eq(@wb.storekeeper)
    db.storekeeper_place.should eq(@wb.storekeeper_place)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 500)
    db.add_item(tag: 'nails', mu: 'kg', amount: 2)
    db.items.count.should eq(2)
    lambda { db.save } .should change(Allocation, :count).by(1)
    db.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    db.items[0].amount.should eq(500)
    db.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    db.items[1].amount.should eq(2)

    db = Allocation.find(db)
    db.items.count.should eq(2)
    db.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    db.items[0].amount.should eq(500)
    db.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    db.items[1].amount.should eq(2)
  end

  it 'should create deals' do
    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 200)
    lambda { db.save } .should change(Deal, :count).by(2)

    deal = Deal.find(db.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.allocation.deal.tag',
                              id: Allocation.last.nil? ? 1 : Allocation.last.id))
    deal.entity.should eq(db.storekeeper)
    deal.isOffBalance.should be_true

    roof_deal_tag = Waybill.first.items.first.warehouse_deal(nil,
      db.storekeeper_place, db.storekeeper).tag
    deal = db.items.first.warehouse_deal(nil, db.storekeeper_place, db.storekeeper)
    deal.tag.should eq(roof_deal_tag)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    deal = db.items.first.warehouse_deal(nil, db.foreman_place, db.foreman)
    deal.tag.should eq(I18n.t('activerecord.attributes.allocation.deal.resource.tag',
                              id: Allocation.last.nil? ? 1 : Allocation.last.id,
                              index: 1))
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: @wb.distributor,
                         distributor_place: @wb.distributor_place,
                         storekeeper: @wb.storekeeper,
                         storekeeper_place: @wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    lambda { wb.save; wb.apply } .should change(Deal, :count).by(3)

    db = build(:allocation, storekeeper: db.storekeeper,
                            storekeeper_place: db.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 20)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    db.add_item(tag: 'hammer', mu: 'th', amount: 50)
    lambda { db.save } .should change(Deal, :count).by(4)

    deal = Deal.find(db.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.allocation.deal.tag',
                              id: Allocation.last.nil? ? 1 : Allocation.last.id))
    deal.entity.should eq(db.storekeeper)
    deal.isOffBalance.should be_true

    db.items.each_with_index do |i, idx|
      deal = i.warehouse_deal(nil, db.storekeeper_place, db.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, db.foreman_place, db.foreman)
      deal.tag.should eq(I18n.t('activerecord.attributes.allocation.deal.resource.tag',
                                id: Allocation.last.nil? ? 1 : Allocation.last.id,
                                index: idx + 1))
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end
  end

  it 'should create rules' do
    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 200)
    lambda { db.save } .should change(Rule, :count).by(1)

    rule = db.deal.rules.first
    rule.rate.should eq(200)
    db.items.first.warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper).should eq(rule.from)
    db.items.first.warehouse_deal(nil, db.foreman_place,
      db.foreman).should eq(rule.to)

    db = build(:allocation, storekeeper: db.storekeeper,
                            storekeeper_place: db.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 150)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 300)
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
    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 5)
    db.state.should eq(Allocation::UNKNOWN)

    db.cancel.should be_false

    db.save!
    db.state.should eq(Allocation::INWORK)

    db = Allocation.find(db)
    db.cancel.should be_true
    db.state.should eq(Allocation::CANCELED)

    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 1)
    db.save!
    db.apply.should be_true
    db.state.should eq(Allocation::APPLIED)
  end

  it 'should create facts by rules after apply' do
    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 5)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 10)

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

describe AllocationItemsValidator do
  it 'should not validate' do
    create(:chart)
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2',  amount: 500, price: 10.0)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb.save!
    wb.apply

    db = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    db.add_item(tag: '', mu: 'm2', amount: 1)
    db.should be_invalid
    db.items.clear
    db.add_item(tag: 'roof', mu: 'm2', amount: 0)
    db.should be_invalid
    db.items.clear
    db.add_item(tag: 'roof', mu: 'm2', amount: 500)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 1201)
    db.should be_invalid
    db.items.clear
    db.add_item(tag: 'roof', mu: 'm2', amount: 300)
    db.save!

    db2 = build(:allocation, storekeeper: wb.storekeeper,
                             storekeeper_place: wb.storekeeper_place)
    db2.add_item(tag: 'roof', mu: 'm2', amount: 201)
    db2.should be_invalid

    db.cancel
    db.add_item(tag: 'roof', mu: 'm2', amount: 201)
    db.should be_valid
  end
end
