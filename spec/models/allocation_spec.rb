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
    user = create(:user)
    create(:credential, user: user, document_type: Allocation.name)
    PaperTrail.whodunnit = user

    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 5)
    db.state.should eq(Allocation::UNKNOWN)

    db.cancel.should be_false

    db.save!
    db.state.should eq(Allocation::INWORK)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(db.id)
    comment.item_type.should eq(db.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.allocation.comment.create'))

    db = Allocation.find(db)
    db.cancel.should be_true
    db.state.should eq(Allocation::CANCELED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(db.id)
    comment.item_type.should eq(db.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.allocation.comment.cancel'))

    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 1)
    db.save!
    db.apply.should be_true
    db.state.should eq(Allocation::APPLIED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(db.id)
    comment.item_type.should eq(db.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.allocation.comment.apply'))

    db = Allocation.find(db)
    db.cancel.should be_true
    db.state.should eq(Allocation::REVERSED)

    comment = Comment.last
    comment.user_id.should eq(user.id)
    comment.item_id.should eq(db.id)
    comment.item_type.should eq(db.class.name)
    comment.message.should eq(I18n.t('activerecord.attributes.allocation.comment.reverse'))

    db = build(:allocation, storekeeper: @wb.storekeeper,
               storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 1)
    db.save!
    db.apply.should be_true
    db.state.should eq(Allocation::APPLIED)

    PaperTrail.whodunnit = nil
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

  it 'should create facts by rules after disable' do
    db = build(:allocation, storekeeper: @wb.storekeeper,
                            storekeeper_place: @wb.storekeeper_place)
    db.add_item(tag: 'roof', mu: 'm2', amount: 5)
    db.add_item(tag: 'nails', mu: 'pcs', amount: 10)

    roof_deal = db.items[0].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper)
    nails_deal = db.items[1].warehouse_deal(nil, db.storekeeper_place,
      db.storekeeper)

    roof_deal.state.amount.should eq(594.0)
    nails_deal.state.amount.should eq(1190.0)

    db.save.should be_true
    expect { db.apply } .to change(Fact, :count).by(3)

    roof_deal.state.amount.should eq(589.0)
    nails_deal.state.amount.should eq(1180.0)

    expect { db.cancel } .to change(Fact, :count).by(3)
    db.state.should eq(Statable::REVERSED)

    roof_deal.state.amount.should eq(594.0)
    nails_deal.state.amount.should eq(1190.0)
  end

  it "should filter by warehouse" do
    moscow = create(:place)
    minsk = create(:place)
    ivanov = create(:entity)
    petrov = create(:entity)

    wb1 = build(:waybill, storekeeper: ivanov,
                          storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!
    wb1.apply

    db1 = build(:allocation, storekeeper: ivanov,
                            storekeeper_place: moscow)
    db1.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db1.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    db1.save!

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!
    wb2.apply

    db2 = build(:allocation, storekeeper: ivanov,
                            storekeeper_place: moscow)
    db2.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db2.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    db2.save!

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!
    wb3.apply

    db3 = build(:allocation, storekeeper: petrov,
                            storekeeper_place: minsk)
    db3.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db3.add_item(tag: 'nails', mu: 'kg', amount: 10)
    db3.save!

    Allocation.by_warehouse(moscow).should =~ [db1, db2]
    Allocation.by_warehouse(minsk).should =~ [db3]
    Allocation.by_warehouse(create(:place)).all.should be_empty
  end

  it 'should sort allocations' do
    moscow = create(:place, tag: 'Moscow1')
    kiev = create(:place, tag: 'Kiev1')
    amsterdam = create(:place, tag: 'Amsterdam1')
    ivanov = create(:entity, tag: 'Ivanov1')
    petrov = create(:entity, tag: 'Petrov1')
    antonov = create(:entity, tag: 'Antonov1')
    pupkin = create(:entity, tag: 'Pupkin')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 11,
                distributor: petrov, storekeeper: ivanov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'foo', mu: 'rm', amount: 100, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 13,
                distributor: ivanov, storekeeper: pupkin,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'foo', mu: 'rm', amount: 100, price: 120.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 12,
                distributor: pupkin, storekeeper: antonov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'foo', mu: 'rm', amount: 100, price: 120.0)
    wb3.save!
    wb3.apply

    al1 = build(:allocation, created: Date.new(2011,11,11),
                storekeeper: wb1.storekeeper, storekeeper_place: wb1.storekeeper_place,
                foreman: pupkin)
    al1.add_item(tag: 'foo', mu: 'rm', amount: 33)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,11,12),
                storekeeper: wb2.storekeeper, storekeeper_place: wb2.storekeeper_place,
                foreman: antonov)
    al2.add_item(tag: 'foo', mu: 'rm', amount: 33)
    al2.save!

    al3 = build(:allocation, created: Date.new(2011,11,13),
                storekeeper: wb3.storekeeper, storekeeper_place: wb3.storekeeper_place,
                foreman: ivanov)
    al3.add_item(tag: 'foo', mu: 'rm', amount: 33)
    al3.save!
    al3.apply

    als = Allocation.order_by({field: 'created', type: 'acs'}).all
    als_test = Allocation.order('created').all
    als.should eq(als_test)
    als = Allocation.order_by({field: 'created', type: 'desc'}).all
    als_test = Allocation.order('created DESC').all
    als.should eq(als_test)

    als = Allocation.order_by({field: 'storekeeper', type: 'acs'}).all
    als_test = Allocation.joins{deal.entity(Entity)}.order('entities.tag').all
    als.should eq(als_test)
    als = Allocation.order_by({field: 'storekeeper', type: 'desc'}).all
    als_test = Allocation.joins{deal.entity(Entity)}.order('entities.tag DESC').all
    als.should eq(als_test)

    als = Allocation.order_by({field: 'storekeeper_place', type: 'acs'}).all
    als_test = Allocation.joins{deal.give.place}.order('places.tag').all
    als.should eq(als_test)
    als = Allocation.order_by({field: 'storekeeper_place', type: 'desc'}).all
    als_test = Allocation.joins{deal.give.place}.order('places.tag DESC').all
    als.should eq(als_test)

    als = Allocation.order_by({field: 'foreman', type: 'acs'}).all
    als_test = Allocation.joins{deal.rules.to.entity(Entity)}.
        group('allocations.id, allocations.created, allocations.deal_id, entities.tag').
        order('entities.tag').all
    als.should eq(als_test)
    als = Allocation.order_by({field: 'foreman', type: 'desc'}).all
    als_test = Allocation.joins{deal.rules.to.entity(Entity)}.
        group('allocations.id, allocations.created, allocations.deal_id, entities.tag').
        order('entities.tag DESC').all
    als.should eq(als_test)
  end

  it 'should search allocations' do
    moscow = create(:place)
    kiev = create(:place)
    amsterdam = create(:place)
    ivanov = create(:entity)
    petrov = create(:entity)
    antonov = create(:entity)
    pupkin = create(:entity)

    wb1 = build(:waybill, created: Date.new(2011,12,11), document_id: 111,
                distributor: petrov, storekeeper: ivanov,
                storekeeper_place: moscow)
    wb1.add_item(tag: '2foo', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: '2foo2', mu: 'rm2', amount: 100, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,12,12), document_id: 131,
                distributor: ivanov, storekeeper: pupkin,
                storekeeper_place: kiev)
    wb2.add_item(tag: '2foo', mu: 'rm', amount: 100, price: 120.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, created: Date.new(2011,12,13), document_id: 121,
                distributor: pupkin, storekeeper: antonov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: '2foo', mu: 'rm', amount: 100, price: 120.0)
    wb3.save!
    wb3.apply

    al1 = build(:allocation, created: Date.new(2011,12,11),
                storekeeper: wb1.storekeeper, storekeeper_place: wb1.storekeeper_place,
                foreman: pupkin)
    al1.add_item(tag: '2foo', mu: 'rm', amount: 33)
    al1.add_item(tag: '2foo2', mu: 'rm2', amount: 33)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,12,12),
                storekeeper: wb2.storekeeper, storekeeper_place: wb2.storekeeper_place,
                foreman: antonov)
    al2.add_item(tag: '2foo', mu: 'rm', amount: 33)
    al2.save!

    al3 = build(:allocation, created: Date.new(2011,12,13),
                storekeeper: wb3.storekeeper, storekeeper_place: wb3.storekeeper_place,
                foreman: ivanov)
    al3.add_item(tag: '2foo', mu: 'rm', amount: 33)
    al3.save!
    al3.apply

    Allocation.search({"created" => al1.created.strftime('%Y-%m-%d')}).should =~ [al1]
    Allocation.search({"created" => al1.created.strftime('%Y-%m-%d')[0, 4]}).
        should =~ Allocation.
        where{to_char(created, 'YYYY-MM-DD').
          like(lower("%#{al1.created.strftime('%Y-%m-%d')[0, 4]}%"))}
    Allocation.search({"created" => DateTime.now.strftime('%Y-%m-%d')}).should be_empty

    Allocation.search({"state" => Statable::INWORK}).should =~ Allocation.
        joins{deal.deal_state}.where{deal.deal_state.closed == nil}

    Allocation.search({"storekeeper" => al1.storekeeper.tag}).should =~ [al1]
    Allocation.search({"storekeeper" => al1.storekeeper.tag[0, 4]}).
        should =~ Allocation.joins{deal.entity(Entity)}.
        where{lower(deal.entity.tag).like(lower("%#{al1.storekeeper.tag[0, 4]}%"))}
    Allocation.search({"storekeeper" => create(:entity).tag}).should be_empty

    Allocation.search({"foreman" => al1.foreman.tag}).should =~ [al1]
    Allocation.search({"foreman" => al1.foreman.tag[0, 4]}).
        should =~ Allocation.joins{deal.rules.to.entity(Entity)}.
        where{lower(deal.rules.to.entity.tag).like(lower("%#{al1.foreman.tag[0, 4]}%"))}.
        select("DISTINCT ON (allocations.id) allocations.*")
    Allocation.search({"foreman" => create(:entity).tag}).should be_empty

    Allocation.search({"storekeeper_place" => al1.storekeeper_place.tag}).should =~ [al1]
    Allocation.search({"storekeeper_place" => al1.storekeeper_place.tag[0, 4]}).
        should =~ Allocation.joins{deal.give.place}.
        where{lower(deal.give.place.tag).like(lower("%#{al1.storekeeper_place.tag[0, 4]}%"))}
    Allocation.search({"storekeeper_place" => create(:place).tag}).should be_empty

    Allocation.search({"resource_tag" => al1.items[1].resource.tag}).should =~ [al1]
    Allocation.search({"resource_tag" => al1.items[0].resource.tag}).
        should =~ Allocation.joins{deal.rules.from.give.resource(Asset)}.
        where do
          lower(deal.rules.from.give.resource.tag).
              like(lower("%#{al1.items[0].resource.tag}%"))
        end.select("DISTINCT ON (allocations.id) allocations.*")
    Allocation.search({"resource_tag" => create(:asset).tag}).should be_empty

    Allocation.search({"resource_tag" => al1.items[0].resource.tag,
                       "created" => al2.created.strftime('%Y-%m-%d')}).should =~ [al2]

    Allocation.search({"foreman" => al2.foreman.tag,
                       "storekeeper" => al2.storekeeper.tag}).should =~ [al2]
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
