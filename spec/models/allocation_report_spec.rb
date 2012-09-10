# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe AllocationReport do
  before(:all) do
    create(:chart)
  end

  it 'should select with resources' do
    antonov = create(:entity, tag: 'Antonov')
    pupkin = create(:entity, tag: 'Pupkin')

    wb1 = build(:waybill)
    wb2 = build(:waybill)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb1.add_item(tag: 'nails', mu: 'kg', amount: 100, price: 150.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 100, price: 150.0)
    wb1.save!
    wb2.save!
    wb1.apply
    wb2.apply

    al1 = build(:allocation, created: Date.new(2011,11,11),
                storekeeper: wb1.storekeeper, storekeeper_place: wb1.storekeeper_place,
                foreman: pupkin)
    al1.add_item(tag: 'nails', mu: 'pcs', amount: 100)
    al1.add_item(tag: 'nails', mu: 'kg', amount: 33)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,11,12),
                storekeeper: wb2.storekeeper, storekeeper_place: wb2.storekeeper_place,
                foreman: antonov)
    al2.add_item(tag: 'nails', mu: 'kg', amount: 40)
    al2.save!

    als = AllocationReport.with_resources.select_all.order{deal.rules.from.give.resource.id}

    als[0].created.should eq(al1.created)
    als[0].storekeeper.tag.should eq(al1.storekeeper.tag)
    als[0].storekeeper_place.tag.should eq(al1.storekeeper_place.tag)
    als[0].foreman.tag.should eq(al1.foreman.tag)
    als[0].state.should eq(al1.state)
    als[0].resource_tag.should eq(al1.items[0].resource.tag)
    als[0].resource_mu.should eq(al1.items[0].resource.mu)
    Converter.float(als[0].resource_amount).should eq(al1.items[0].amount)

    als[1].created.should eq(al1.created)
    als[1].storekeeper.tag.should eq(al1.storekeeper.tag)
    als[1].storekeeper_place.tag.should eq(al1.storekeeper_place.tag)
    als[1].foreman.tag.should eq(al1.foreman.tag)
    als[1].state.should eq(al1.state)
    als[1].resource_tag.should eq(al1.items[1].resource.tag)
    als[1].resource_mu.should eq(al1.items[1].resource.mu)
    Converter.float(als[1].resource_amount).should eq(al1.items[1].amount)

    als[2].created.should eq(al2.created)
    als[2].storekeeper.tag.should eq(al2.storekeeper.tag)
    als[2].storekeeper_place.tag.should eq(al2.storekeeper_place.tag)
    als[2].foreman.tag.should eq(al2.foreman.tag)
    als[2].state.should eq(al2.state)
    als[2].resource_tag.should eq(al2.items[0].resource.tag)
    als[2].resource_mu.should eq(al2.items[0].resource.mu)
    Converter.float(als[2].resource_amount).should eq(al2.items[0].amount)
  end

  it 'should sort allocations with resources' do
    moscow = create(:place, tag: 'Moscow1')
    kiev = create(:place, tag: 'Kiev1')
    amsterdam = create(:place, tag: 'Amsterdam1')
    ivanov = create(:entity, tag: 'Ivanov1')
    petrov = create(:entity, tag: 'Petrov1')
    antonov = create(:entity, tag: 'Antonov1')
    pupkin = create(:entity, tag: 'Pupkin1')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 11,
                distributor: petrov, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 244, price: 120.0)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 235, price: 110.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 13,
                distributor: antonov, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 250, price: 220.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 12,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'briks', mu: 't', amount: 310, price: 10.0)
    wb3.save!
    wb3.apply

    al1 = build(:allocation, created: Date.new(2011,11,14),
                storekeeper: wb1.storekeeper, storekeeper_place: wb1.storekeeper_place,
                foreman: pupkin)
    al1.add_item(tag: 'nails', mu: 'pcs', amount: 100)
    al1.add_item(tag: 'roof', mu: 'rm', amount: 33)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,11,15),
                storekeeper: wb2.storekeeper, storekeeper_place: wb2.storekeeper_place,
                foreman: pupkin)
    al2.add_item(tag: 'nails', mu: 'kg', amount: 10)
    al2.save!

    al3 = build(:allocation, created: Date.new(2011,11,16),
                storekeeper: wb3.storekeeper, storekeeper_place: wb3.storekeeper_place,
                foreman: petrov)
    al3.add_item(tag: 'briks', mu: 't', amount: 50)
    al3.save!
    al3.apply

    als = AllocationReport.order_by(field: 'created', type: 'asc').all
    als_test = AllocationReport.order('created').all
    als.should eq(als_test)
    als = AllocationReport.order_by(field: 'created', type: 'desc').all
    als_test = AllocationReport.order('created DESC').all
    als.should eq(als_test)

    als = AllocationReport.order_by(field: 'storekeeper', type: 'asc').all
    als_test = AllocationReport.joins{deal.entity(Entity)}.order('entities.tag').all
    als.should eq(als_test)
    als = AllocationReport.order_by(field: 'storekeeper', type: 'desc').all
    als_test = AllocationReport.joins{deal.entity(Entity)}.order('entities.tag DESC').all
    als.should eq(als_test)

    als = AllocationReport.order_by(field: 'storekeeper_place', type: 'asc').all
    als_test = AllocationReport.joins{deal.give.place}.order('places.tag').all
    als.should eq(als_test)
    als = AllocationReport.order_by(field: 'storekeeper_place', type: 'desc').all
    als_test = AllocationReport.joins{deal.give.place}.order('places.tag DESC').all
    als.should eq(als_test)

    als = AllocationReport.select_all.with_resources.
        order_by(field: 'foreman', type: 'asc').all
    als_test = AllocationReport.joins{deal.rules.to.entity(Entity)}.order('entities.tag').all
    als.should eq(als_test)
    als = AllocationReport.order_by(field: 'foreman', type: 'desc').all
    als_test = AllocationReport.joins{deal.rules.to.entity(Entity)}.
        order('entities.tag DESC').all
    als.should eq(als_test)

    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_tag', type: 'asc').all
    als_test = AllocationReport.select_all.with_resources.order('assets.tag').all
    als.should eq(als_test)
    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_tag', type: 'desc').all
    als_test = AllocationReport.select_all.with_resources.order('assets.tag DESC').all
    als.should eq(als_test)

    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_mu', type: 'asc').all
    als_test = AllocationReport.select_all.with_resources.order('assets.mu').all
    als.should eq(als_test)
    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_mu', type: 'desc').all
    als_test = AllocationReport.select_all.with_resources.order('assets.mu DESC').all
    als.should eq(als_test)

    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_amount', type: 'asc').all
    als_test = AllocationReport.select_all.with_resources.order('rules.rate').all
    als.should eq(als_test)
    als = AllocationReport.select_all.with_resources.
        order_by(field: 'resource_amount', type: 'desc').all
    als_test = AllocationReport.select_all.with_resources.order('rules.rate DESC').all
    als.should eq(als_test)
  end

  it 'should filter allocations with resources' do
    moscow = create(:place, tag: 'Moscow2')
    kiev = create(:place, tag: 'Kiev2')
    amsterdam = create(:place, tag: 'Amsterdam2')
    ivanov = create(:entity, tag: 'Ivanov2')
    petrov = create(:entity, tag: 'Petrov2')
    antonov = create(:entity, tag: 'Antonov2')
    pupkin = create(:entity, tag: 'Pupkin2')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 21,
                distributor: petrov, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 244, price: 120.0)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 235, price: 110.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 23,
                distributor: antonov, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 250, price: 220.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 22,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'briks', mu: 't', amount: 310, price: 10.0)
    wb3.save!
    wb3.apply

    al1 = build(:allocation, created: Date.new(2011,11,14),
                storekeeper: wb1.storekeeper, storekeeper_place: wb1.storekeeper_place,
                foreman: ivanov)
    al1.add_item(tag: 'nails', mu: 'pcs', amount: 100)
    al1.add_item(tag: 'roof', mu: 'rm', amount: 33)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,11,15),
                storekeeper: wb2.storekeeper, storekeeper_place: wb2.storekeeper_place,
                foreman: pupkin)
    al2.add_item(tag: 'nails', mu: 'kg', amount: 10)
    al2.save!

    al3 = build(:allocation, created: Date.new(2011,11,16),
                storekeeper: wb3.storekeeper, storekeeper_place: wb3.storekeeper_place,
                foreman: petrov)
    al3.add_item(tag: 'briks', mu: 't', amount: 50)
    al3.save!
    al3.apply

    als = AllocationReport.search(created: '15').all
    als_test = AllocationReport.where{to_char(created, 'YYYY-MM-DD').like("%15%")}.all
    als. =~ als_test

    als = AllocationReport.select_all.with_resources.search('foreman' => 'o').all
    als_test = AllocationReport.joins{deal.rules.to.entity(Entity)}.
        where("entities.tag LIKE '%o%'").all
    als. =~ als_test

    als = AllocationReport.search('storekeeper' => 'a').all
    als_test = AllocationReport.joins{deal.entity(Entity)}.
        where{lower(deal.entity.tag).like(lower("%a%"))}.all
    als. =~ als_test

    als = AllocationReport.search('storekeeper_place' => 'e').all
    als_test = AllocationReport.joins{deal.give.place}.where("places.tag LIKE '%e%'").all
    als. =~ als_test

    als = AllocationReport.select_all.with_resources.search('state' => '1').all
    als_test = AllocationReport.select_all.with_resources.joins{deal.deal_state}.
        joins{deal.to_facts.outer}.where("deal_states.closed IS NULL").all
    als. =~ als_test

    als = AllocationReport.select_all.with_resources.search('resource_tag' => 'r').all
    als_test = AllocationReport.select_all.with_resources.where("assets.tag LIKE '%r%'").all
    als. =~ als_test
  end
end
