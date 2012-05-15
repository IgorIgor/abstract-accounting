# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Waybill do
  before(:all) do
    create(:chart)
  end

  it 'should have next behaviour' do
    wb = build(:waybill)
    wb.add_item('roof', 'rm', 100, 120.0)
    wb.save
    should validate_presence_of :document_id
    should validate_presence_of :distributor
    should validate_presence_of :storekeeper
    should validate_presence_of :distributor_place
    should validate_presence_of :storekeeper_place
    should validate_presence_of :created
    should validate_uniqueness_of :document_id
    should belong_to :distributor
    should belong_to :storekeeper
    should belong_to(:distributor_place).class_name(Place)
    should belong_to(:storekeeper_place).class_name(Place)
    should have_many(Waybill.versions_association_name)
  end

  it 'should create items' do
    wb = build(:waybill)
    wb.add_item('nails', 'pcs', 1200, 1.0)
    wb.add_item('nails', 'kg', 10, 150.0)
    lambda { wb.save } .should change(Asset, :count).by(2)
    wb.items.count.should eq(2)
    wb.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    wb.items[0].amount.should eq(1200)
    wb.items[0].price.should eq(1.0)
    wb.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    wb.items[1].amount.should eq(10)
    wb.items[1].price.should eq(150.0)

    asset = create(:asset)
    wb.add_item(asset.tag, asset.mu, 100, 12.0)
    lambda { wb.save } .should_not change(Asset, :count)
    wb.items.count.should eq(3)
    wb.items[2].resource.should eq(asset)
    wb.items[2].amount.should eq(100)
    wb.items[2].price.should eq(12.0)

    wb = Waybill.find(wb)
    wb.items.count.should eq(2)
    wb.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    wb.items[0].amount.should eq(1200)
    wb.items[0].price.should eq(1.0)
    wb.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    wb.items[1].amount.should eq(10)
    wb.items[1].price.should eq(150.0)
  end

  it 'should create deals' do
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 500, 10.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    deal = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor)
    deal.should_not be_nil
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.items.first.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('hammer', 'th', 500, 100.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('hammer', 'th', 50, 100.0)
    lambda { wb.save } .should change(Deal, :count).by(1)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb = build(:waybill, storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('hammer', 'th', 200, 100.0)
    lambda { wb.save } .should change(Deal, :count).by(2)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    deal = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor)
    deal.should_not be_nil
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.items.first.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('roof', 'm2', 70, 12.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                         distributor_place: wb.distributor_place,
                         storekeeper: wb.storekeeper)
    wb.add_item('roof', 'm2', 100, 10.0)
    lambda { wb.save } .should change(Deal, :count).by(2)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end
  end

  it 'should create rules' do
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 500, 10.0)
    lambda { wb.save } .should change(Rule, :count).by(1)

    rule = wb.deal.rules.first
    rule.rate.should eq(500)
    wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('hammer', 'th', 500, 100.0)
    lambda { wb.save } .should change(Rule, :count).by(2)

    rule = wb.deal.rules[0]
    rule.rate.should eq(100)
    wb.items[0].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)

    rule = wb.deal.rules[1]
    rule.rate.should eq(500)
    wb.items[1].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)
  end

  it 'should create fact' do
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 500, 10.0)
    wb.save.should be_true

    state = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('hammer', 'th', 500, 100.0)
    wb.save.should be_true

    state = wb.items[0].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(5000 + 100 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500 + 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create txn' do
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 500, 10.0)
    wb.save.should be_true

    balance = wb.items.first.warehouse_deal(Chart.first.currency,
                                          wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
                                          wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                       distributor_place: wb.distributor_place,
                       storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    wb.add_item('roof', 'm2', 100, 10.0)
    wb.add_item('hammer', 'th', 500, 100.0)
    wb.save.should be_true

    balance = wb.items[0].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(5000 + 100 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq((500 + 100))
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 100)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500)
    balance.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should show in warehouse' do
    moscow = create(:place, tag: 'Moscow')
    minsk = create(:place, tag: 'Minsk')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item('roof', 'rm', 100, 120.0)
    wb1.add_item('nails', 'pcs', 700, 1.0)
    wb1.save!
    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item('nails', 'pcs', 1200, 1.0)
    wb2.add_item('nails', 'kg', 10, 150.0)
    wb2.add_item('roof', 'rm', 50, 100.0)
    wb2.save!
    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item('roof', 'rm', 500, 120.0)
    wb3.add_item('nails', 'kg', 300, 150.0)
    wb3.save!

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    ds_moscow = build(:distribution, storekeeper: ivanov,
                                             storekeeper_place: moscow)
    ds_moscow.add_item('nails', 'pcs', 10)
    ds_moscow.add_item('roof', 'rm', 4)
    ds_moscow.save!
    ds_minsk = build(:distribution, storekeeper: petrov,
                                            storekeeper_place: minsk)
    ds_minsk.add_item('roof', 'rm', 400)
    ds_minsk.add_item('nails', 'kg', 200)
    ds_minsk.save!

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    ds_moscow = build(:distribution, storekeeper: ivanov,
                                             storekeeper_place: moscow)
    ds_moscow.add_item('roof', 'rm', 146)
    ds_moscow.add_item('nails', 'pcs', 1890)
    ds_moscow.save!

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true
  end
end

describe ItemsValidator do
  it 'should not validate' do
    wb = build(:waybill)
    wb.add_item('roof', 'm2', 1, 10.0)
    wb.add_item('roof', 'm2', 1, 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item('', 'm2', 1, 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item('roof', 'm2', 0, 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item('roof', 'm2', 1, 0)
    wb.should be_invalid
  end
end
