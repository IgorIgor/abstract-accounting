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
    wb.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb.save
    should validate_presence_of :document_id
    should validate_presence_of :distributor
    should validate_presence_of :distributor_place
    should validate_presence_of :created
    should validate_presence_of :storekeeper
    should validate_presence_of :storekeeper_place
    should have_many(Waybill.versions_association_name)
    should have_many :comments
  end

  it 'should create items' do
    wb = build(:waybill)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    lambda { wb.save } .should change(Asset, :count).by(2)
    Asset.all
    wb.items.count.should eq(2)
    wb.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    wb.items[0].amount.should eq(1200)
    wb.items[0].price.should eq(1.0)
    wb.items[0].sum.should eq((wb.items[0].amount * wb.items[0].price).accounting_norm)
    wb.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    wb.items[1].amount.should eq(10)
    wb.items[1].price.should eq(150.0)
    wb.items[1].sum.should eq((wb.items[1].amount * wb.items[1].price).accounting_norm)
    wb.sum.should eq(wb.items.inject(0.0) { |mem, item| mem += item.sum })

    asset = create(:asset)
    wb.add_item(tag: asset.tag, mu: asset.mu, amount: 100, price: 12.0)
    lambda { wb.save } .should_not change(Asset, :count)
    wb.items.count.should eq(3)
    wb.items[2].resource.should eq(asset)
    wb.items[2].amount.should eq(100)
    wb.items[2].price.should eq(12.0)
    wb.items[2].sum.should eq((wb.items[2].amount * wb.items[2].price).accounting_norm)
    wb.sum.should eq(wb.items.inject(0.0) { |mem, item| mem += item.sum })

    wb = Waybill.find(wb)
    wb.items.count.should eq(3)
    wb.items.each do |item|
      if item.resource == Asset.find_all_by_tag_and_mu('nails', 'pcs').first
        item.amount.should eq(1200)
        item.price.should eq(1.0)
        item.sum.should eq((item.amount * item.price).accounting_norm)
      elsif item.resource == Asset.find_all_by_tag_and_mu('nails', 'kg').first
        item.amount.should eq(10)
        item.price.should eq(150.0)
        item.sum.should eq((item.amount * item.price).accounting_norm)
      elsif item.resource == asset
        item.resource.should eq(asset)
        item.amount.should eq(100)
        item.price.should eq(12.0)
        item.sum.should eq((item.amount * item.price).accounting_norm)
      else
        false.should be_true
      end
    end

    wb = build(:waybill)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150)
    wb.save
    wb.sum.should eq(wb.items.inject(0.0) { |mem, item| mem += item.sum })

    Waybill.total.should eq(Waybill.all.inject(0.0) { |mem, w| mem += w.sum })
  end

  it 'should create deals' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    last_deal_id = Deal.count > 0 ? Deal.last.id + 1 : 1
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.waybill.deal.tag',
                              id: wb.document_id, place: wb.storekeeper_place.tag,
                              deal_id: last_deal_id))
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    roof_deal_tag = I18n.t("activerecord.attributes.waybill.deal.resource.tag",
                  id: wb.document_id,
                  index: 1, deal_id: wb.deal_id)
    deal = wb.create_distributor_deal(wb.items.first, 0)
    deal.should_not be_nil
    deal.tag.should eq(roof_deal_tag)
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.create_storekeeper_deal(wb.items.first, 0)
    deal.tag.should eq(roof_deal_tag)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    last_deal_id = Deal.last.id + 1
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.waybill.deal.tag',
                              id: wb.document_id, place: wb.storekeeper_place.tag,
                              deal_id: last_deal_id))
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each_with_index do |i, idx|
      deal_tag = I18n.t("activerecord.attributes.waybill.deal.resource.tag",
                        id: wb.document_id,
                        index: idx + 1, deal_id: wb.deal_id)
      deal = wb.create_distributor_deal(i, idx)
      deal.tag.should eq(wb.items[idx].resource.tag == 'roof' ? roof_deal_tag : deal_tag)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = wb.create_storekeeper_deal(i, idx)
      deal.tag.should eq(wb.items[idx].resource.tag == 'roof' ? roof_deal_tag : deal_tag)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 50, price: 100.0)
    lambda { wb.save } .should change(Deal, :count).by(1)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb = build(:waybill, storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 200, price: 100.0)
    lambda { wb.save } .should change(Deal, :count).by(2)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    deal = wb.create_distributor_deal(wb.items.first, 0)
    deal.should_not be_nil
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.create_storekeeper_deal(wb.items.first, 0)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 70, price: 12.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i, idx|
      deal = wb.create_distributor_deal(i, idx)
      deal.should_not be_nil
      deal.rate.accounting_norm.should eq((1 / i.price).accounting_norm)
      deal.isOffBalance.should be_false

      deal = wb.create_storekeeper_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                         distributor_place: wb.distributor_place,
                         storekeeper: wb.storekeeper,
                         storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(1)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i, idx|
      deal = wb.create_distributor_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = wb.create_storekeeper_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                         distributor_place: wb.distributor_place,
                         storekeeper: wb.storekeeper,
                         storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'rOOf', mu: 'm2', amount: 100, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(1)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i, idx|
      deal = wb.create_distributor_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = wb.create_storekeeper_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 120.34, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 128.4, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i, idx|
      deal = wb.create_distributor_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = wb.create_storekeeper_deal(i, idx)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end
  end

  it 'should create rules' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    lambda { wb.save } .should change(Rule, :count).by(1)

    rule = wb.deal.rules.first
    rule.rate.should eq(500)
    wb.create_distributor_deal(wb.items.first, 0).should eq(rule.from)
    wb.create_storekeeper_deal(wb.items.first, 0).should eq(rule.to)

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    lambda { wb.save } .should change(Rule, :count).by(2)

    wb.deal.rules.each do |rule|
      if rule.rate == 100
        wb.create_distributor_deal(wb.items[0], 0).should eq(rule.from)
        wb.create_storekeeper_deal(wb.items[0], 0).should eq(rule.to)
      elsif rule.rate == 500
        wb.create_distributor_deal(wb.items[1], 1).should eq(rule.from)
        wb.create_storekeeper_deal(wb.items[1], 1).should eq(rule.to)
      else
        false.should be_true
      end
    end

    wb = build(:waybill)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 120.34, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 128.4, price: 10.0)
    lambda { wb.save } .should change(Rule, :count).by(3)

    wb.items.each_with_index do |item, idx|
      rule = wb.deal.rules.where{rate == item.amount}.first
      rule.should_not be_nil
      wb.create_distributor_deal(item, idx).should eq(rule.from)
      wb.create_storekeeper_deal(item, idx).should eq(rule.to)
    end
  end

  it 'should change state' do
    PaperTrail.enabled = true
    user = create(:user)
    create(:credential, user: user, document_type: Waybill.name)
    PaperTrail.whodunnit = user

    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.state.should eq(Waybill::UNKNOWN)

    wb.cancel.should be_false

    wb.save!
    wb.state.should eq(Waybill::INWORK)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(wb.id)
    comment.item_type.should eq(wb.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.waybill.comment.create'))

    wb.update_attributes(:distributor_id => create(:entity).id,
                         :distributor_type => Entity.name,
                         :distributor_place_id => create(:place).id)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(wb.id)
    comment.item_type.should eq(wb.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.waybill.comment.update'))

    wb = Waybill.find(wb)
    wb.cancel.should be_true
    wb.state.should eq(Waybill::CANCELED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(wb.id)
    comment.item_type.should eq(wb.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.waybill.comment.cancel'))

    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save!
    wb.apply.should be_true
    wb.state.should eq(Waybill::APPLIED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(wb.id)
    comment.item_type.should eq(wb.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.waybill.comment.apply'))

    wb = Waybill.find(wb)
    wb.reverse.should be_true
    wb.state.should eq(Waybill::REVERSED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(wb.id)
    comment.item_type.should eq(wb.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.waybill.comment.reverse'))

    PaperTrail.whodunnit = nil
    PaperTrail.enabled = false
  end

  it 'should create fact after apply' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.create_distributor_deal(wb.items.first, 0).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items.first, 0).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.create_distributor_deal(wb.items[0], 0).state
    state.side.should eq("passive")
    state.amount.should eq(5000 + 100 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items[0], 0).state
    state.side.should eq("active")
    state.amount.should eq(500 + 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_distributor_deal(wb.items[1], 1).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items[1], 1).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create txn after apply' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.create_distributor_deal(wb.items[0], 0).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[0], 0).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                       distributor_place: wb.distributor_place,
                       storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.create_distributor_deal(wb.items[0], 0).balance
    balance.side.should eq("passive")
    balance.amount.should eq(5000 + 100 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[0], 0).balance
    balance.side.should eq("active")
    balance.amount.should eq((500 + 100))
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_distributor_deal(wb.items[1], 1).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 100)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[1], 1).balance
    balance.side.should eq("active")
    balance.amount.should eq(500)
    balance.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create fact after disable' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.create_distributor_deal(wb.items[0], 0).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items[0], 0).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb_old = wb
    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.create_distributor_deal(wb.items[0], 0).state
    state.side.should eq("passive")
    state.amount.should eq(5000 + 100 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items[0], 0).state
    state.side.should eq("active")
    state.amount.should eq(500 + 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_distributor_deal(wb.items[1], 1).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.create_storekeeper_deal(wb.items[1], 1).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb.reverse.should be_true
    wb.state.should eq(Waybill::REVERSED)

    state = wb_old.create_distributor_deal(wb.items[0], 0).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb_old.create_storekeeper_deal(wb.items[0], 0).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create txn after disable' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.create_distributor_deal(wb.items[0], 0).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[0], 0).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb_old = wb
    wb = build(:waybill, distributor: wb.distributor,
                       distributor_place: wb.distributor_place,
                       storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.create_distributor_deal(wb.items[0], 0).balance
    balance.side.should eq("passive")
    balance.amount.should eq(5000 + 100 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[0], 0).balance
    balance.side.should eq("active")
    balance.amount.should eq((500 + 100))
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_distributor_deal(wb.items[1], 1).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 100)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.create_storekeeper_deal(wb.items[1], 1).balance
    balance.side.should eq("active")
    balance.amount.should eq(500)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb.reverse.should be_true
    wb.state.should eq(Waybill::REVERSED)

    balance = wb_old.create_distributor_deal(wb.items[0], 0).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb_old.create_storekeeper_deal(wb.items[0], 0).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should show in warehouse' do
    moscow = create(:place, tag: 'Moscow')
    minsk = create(:place, tag: 'Minsk')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!
    wb1.apply.should be_true
    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!
    wb2.apply.should be_true
    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!
    wb3.apply.should be_true

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    ds_moscow = build(:allocation, storekeeper: ivanov,
                                   storekeeper_place: moscow)
    ds_moscow.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    ds_moscow.add_item(tag: 'roof', mu: 'rm', amount: 4)
    ds_moscow.save!
    ds_moscow.apply.should be_true
    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 400)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 200)
    ds_minsk.save!
    ds_minsk.apply.should be_true

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    wbs = Waybill.without([ wb1.id ]).in_warehouse
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_true
    wbs.include?(wb3).should be_true

    wbs = Waybill.without([ wb1.id, wb3.id ]).in_warehouse
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_true
    wbs.include?(wb3).should be_false

    ds_moscow = build(:allocation, storekeeper: ivanov,
                                   storekeeper_place: moscow)
    ds_moscow.add_item(tag: 'roof', mu: 'rm', amount: 146)
    ds_moscow.add_item(tag: 'nails', mu: 'pcs', amount: 1890)
    ds_moscow.save!
    ds_moscow.apply.should be_true

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    wbs = Waybill.by_warehouse(minsk).in_warehouse
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_false
    wbs.include?(wb3).should be_true

    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 100)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 100)
    ds_minsk.save!
    ds_minsk.apply.should be_true

    wbs = Waybill.by_warehouse(minsk).in_warehouse
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_false
    wbs.include?(wb3).should be_false

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_false

    wb4 = build(:waybill, storekeeper: ivanov,
                          storekeeper_place: moscow)
    wb4.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb4.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb4.save!

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_false
    Waybill.in_warehouse.include?(wb4).should be_false
  end

  describe "#without" do
    it 'should remove waybills with ids equal to scope attribute' do
      moscow = create(:place)
      minsk = create(:place)
      ivanov = create(:entity)
      petrov = create(:entity)

      wb1 = build(:waybill, storekeeper: ivanov,
                                    storekeeper_place: moscow)
      wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
      wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
      wb1.save!
      wb1.apply.should be_true
      wb2 = build(:waybill, storekeeper: ivanov,
                                    storekeeper_place: moscow)
      wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
      wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
      wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
      wb2.save!
      wb2.apply.should be_true
      wb3 = build(:waybill, storekeeper: petrov,
                                    storekeeper_place: minsk)
      wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
      wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
      wb3.save!
      wb3.apply.should be_true

      Waybill.all.include?(wb1).should be_true
      Waybill.all.include?(wb2).should be_true
      Waybill.all.include?(wb3).should be_true

      wbs = Waybill.without([ wb1.id ])
      wbs.include?(wb1).should be_false
      wbs.include?(wb2).should be_true
      wbs.include?(wb3).should be_true

      wbs = Waybill.without([ wb1.id, wb3.id ])
      wbs.include?(wb1).should be_false
      wbs.include?(wb2).should be_true
      wbs.include?(wb3).should be_false
    end
  end

  it "should filter by warehouse" do
    moscow = create(:place)
    minsk = create(:place)
    ivanov = create(:entity)
    petrov = create(:entity)
    sidorov = create(:entity)

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!

    wb4 = build(:waybill, storekeeper: sidorov,
                                  storekeeper_place: moscow)
    wb4.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb4.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb4.save!

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!

    Waybill.by_warehouse(moscow).should =~ [wb1, wb2, wb4]
    Waybill.by_warehouse(minsk).should =~ [wb3]
    Waybill.by_warehouse(create(:place)).all.should be_empty
  end

  it 'should sort waybills' do
    moscow = create(:place, tag: 'Moscow1')
    kiev = create(:place, tag: 'Kiev1')
    amsterdam = create(:place, tag: 'Amsterdam1')
    ivanov = create(:entity, tag: 'Ivanov1')
    petrov = create(:entity, tag: 'Petrov1')
    antonov = create(:entity, tag: 'Antonov1')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 1,
                distributor: petrov, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 3,
                distributor: antonov, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb2.save!

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 2,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb3.save!
    wb3.apply

    wbs = Waybill.order_by(field: 'created', type: 'asc').all
    wbs_test = Waybill.order('created').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'created', type: 'desc').all
    wbs_test = Waybill.order('created DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'document_id', type: 'asc').all
    wbs_test = Waybill.order('document_id').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'document_id', type: 'desc').all
    wbs_test = Waybill.order('document_id DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'distributor', type: 'asc').all
    wbs_test = Waybill.joins{deal.rules.from.entity(LegalEntity).outer}.
        joins{deal.rules.from.entity(Entity).outer}.order("case froms_rules.entity_type
                      when 'Entity'      then entities.tag
                      when 'LegalEntity' then legal_entities.name
                 end").all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'distributor', type: 'desc').all
    wbs_test = Waybill.joins{deal.rules.from.entity(LegalEntity).outer}.
        joins{deal.rules.from.entity(Entity).outer}.order("case froms_rules.entity_type
                      when 'Entity'      then entities.tag
                      when 'LegalEntity' then legal_entities.name
                 end DESC").all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'storekeeper', type: 'asc').all
    wbs_test = Waybill.joins{deal.entity(Entity)}.order('entities.tag').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'storekeeper', type: 'desc').all
    wbs_test = Waybill.joins{deal.entity(Entity)}.order('entities.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'storekeeper_place', type: 'asc').all
    wbs_test = Waybill.joins{deal.take.place}.order('places.tag').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'storekeeper_place', type: 'desc').all
    wbs_test = Waybill.joins{deal.take.place}.order('places.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'sum', type: 'asc').all
    wbs_test = Waybill.joins{deal.rules.from}.
        group('waybills.id, waybills.created, waybills.document_id, waybills.deal_id').
        select("waybills.*").
        select{sum(deal.rules.rate / deal.rules.from.rate).as(:sum)}.
        order("sum").all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'sum', type: 'desc').all
    wbs_test = Waybill.joins{deal.rules.from}.
        group('waybills.id, waybills.created, waybills.document_id, waybills.deal_id').
        select("waybills.*").
        select{sum(deal.rules.rate / deal.rules.from.rate).as(:sum)}.
        order("sum DESC").all
    wbs.should eq(wbs_test)
  end

  it 'should filter waybills' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof_1', mu: 'rm_1', amount: 100, price: 120.0)
    wb.add_item(tag: 'roof_3', mu: 'rm_1', amount: 100, price: 120.0)
    wb.save
    wb.apply
    wb2 = build(:waybill, distributor: wb.distributor)
    wb2.add_item(tag: 'roof_2', mu: 'rm_2', amount: 100, price: 120.0)
    wb2.save

    Waybill.search({ 'created' => wb.created.strftime('%Y-%m-%d'), 'document_id' => wb.document_id,
                     'distributor' => wb.distributor.name, 'storekeeper' => wb.storekeeper.tag,
                     'storekeeper_place' => wb.storekeeper_place.tag }).include?(wb).should be_true
    Waybill.search({ 'created' => wb.created.strftime('%Y-%m-%d'), 'document_id' => wb.document_id,
                     'distributor' => wb.distributor.name, 'storekeeper' => wb.storekeeper.tag,
                     'storekeeper_place' => wb.storekeeper_place.tag }).include?(wb2).should be_false
    Waybill.search({ 'created' => wb2.created.strftime('%Y-%m-%d'), 'document_id' => wb2.document_id,
                     'distributor' => wb2.distributor.name, 'storekeeper' => wb2.storekeeper.tag,
                     'storekeeper_place' => wb2.storekeeper_place.tag }).include?(wb2).should be_true
    Waybill.search({ 'created' => wb2.created.strftime('%Y-%m-%d'), 'document_id' => wb2.document_id,
                     'distributor' => wb2.distributor.name, 'storekeeper' => wb2.storekeeper.tag,
                     'storekeeper_place' => wb2.storekeeper_place.tag }).include?(wb).should be_false

    Waybill.search({ 'created' => wb.created.strftime('%Y-%m-%d') }).include?(wb).should be_true
    Waybill.search({ 'created' => wb.created.strftime('%Y-%m-%d') }).include?(wb2).should be_true

    Waybill.search({ 'state' => Waybill::APPLIED }).include?(wb).should be_true
    Waybill.search({ 'state' => Waybill::APPLIED }).include?(wb2).should be_false
    Waybill.search({ 'state' => Waybill::INWORK }).include?(wb).should be_false
    Waybill.search({ 'state' => Waybill::INWORK }).include?(wb2).should be_true
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb).should be_false
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb2).should be_false
    Waybill.search({ 'state' => Waybill::REVERSED }).include?(wb).should be_false
    Waybill.search({ 'state' => Waybill::REVERSED }).include?(wb2).should be_false

    Waybill.search({ 'created' => wb.created.strftime('%Y-%m-%d'), 'document_id' => wb.document_id,
                     'distributor' => wb.distributor.name, 'storekeeper' => wb.storekeeper.tag,
                     'storekeeper_place' => wb.storekeeper_place.tag }).length.should eq(1)

    Waybill.search({ 'resource_tag' => 'roof_1' }).include?(wb).should be_true
    Waybill.search({ 'resource_tag' => 'roof_1' }).include?(wb2).should be_false


    wb2.cancel.should be_true
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb).should be_false
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb2).should be_true
    wb.reverse.should be_true
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb).should be_false
    Waybill.search({ 'state' => Waybill::CANCELED }).include?(wb2).should be_true
    Waybill.search({ 'state' => Waybill::REVERSED }).include?(wb).should be_true
    Waybill.search({ 'state' => Waybill::REVERSED }).include?(wb2).should be_false
  end

  it "should return all warehouses" do
    5.times { create(:credential, document_type: Waybill.name) }
    5.times { create(:credential) }
    Waybill.warehouses.should =~ Credential.find_all_by_document_type(Waybill.name)

    Waybill.warehouses.each do |w|
      w.tag.should eq(Credential.find(w.id).place.tag)
      w.storekeeper.should eq(Credential.find(w.id).user.entity.tag)
    end
  end

  it "should convert warehouse_id in params" do
    warehouse_id = Credential.find_all_by_document_type(Waybill.name).first.id
    c = Credential.find(warehouse_id)
    Waybill.extract_warehouse(warehouse_id).should eq({ storekeeper_place_id: c.place_id,
                                                         storekeeper_id: c.user.entity_id,
                                                         storekeeper_type: Entity.name })
  end

  it "should return warehouse_id" do
    w = Waybill.first
    u = create(:user, entity: w.storekeeper)
    c = create(:credential, user: u, place: w.storekeeper_place, document_type: Waybill.name)
    w.warehouse_id.should eq(c.id)
    Waybill.new.warehouse_id.should eq(nil)
    PaperTrail.whodunnit = u
    Waybill.new.warehouse_id.should eq(c.id)
    PaperTrail.whodunnit = RootUser.new
    Waybill.new.warehouse_id.should eq(nil)
  end

  it 'should create limits on deals by waybill items' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save

    deal = Deal.find(wb.deal)
    deal.limit.should_not be_nil
    deal.limit.amount.should eq(0)
    deal.limit.side.should eq(Limit::PASSIVE)

    waybill_item = wb.items.first

    roof_deal_give = wb.create_distributor_deal(waybill_item, 0)
    roof_deal_give.limit.should_not be_nil
    roof_deal_give.limit.amount.should eq(0)
    roof_deal_give.limit.side.should eq(Limit::ACTIVE)

    roof_deal_take = wb.create_storekeeper_deal(waybill_item, 0)
    roof_deal_take.limit.should_not be_nil
    roof_deal_take.limit.amount.should eq(0)
    roof_deal_take.limit.side.should eq(Limit::PASSIVE)
  end

  it 'should update_attrs' do
    wb = build :waybill
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save
    ent = create :entity
    leg = create :legal_entity
    wb.update_attributes("storekeeper_place_id" => wb.storekeeper_place.id,
                         "distributor_id" => ent.id,
                         "distributor_type" => Entity.name,
                         "distributor_place_id" => create(:place).id).should be_true
    wb.distributor.id.should eq(ent.id)
    wb.distributor.class.name.should eq(Entity.name)
    wb.update_attributes("storekeeper_place_id" => wb.storekeeper_place.id,
                         "distributor_id" => leg.id,
                         "distributor_type" => LegalEntity.name,
                         "distributor_place_id" => create(:place).id).should be_true
    wb.distributor.id.should eq(leg.id)
    wb.distributor.class.name.should eq(LegalEntity.name)
  end
end

describe ItemsValidator do
  it 'should not validate' do
    wb = build(:waybill)
    wb.add_item(tag: '', mu: 'm2', amount: 1, price: 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item(tag: 'roof', mu: 'm2', amount: 0, price: 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item(tag: 'roof', mu: 'm2', amount: 1, price: 0)
    wb.should be_invalid
  end
end
