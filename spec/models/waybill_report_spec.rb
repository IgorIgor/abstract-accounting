# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe WaybillReport do
  before(:all) do
    create(:chart)
  end

  it 'should select with resources' do
    wb = build(:waybill)
    wb2 = build(:waybill)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb.save
    wb2.save

    wbs = WaybillReport.with_resources.select_all.joins{deal.rules.from.take.resource}.
        order("resource_mu DESC")

    wbs[0].created.to_s.should eq(wb.created.to_s)
    wbs[0].document_id.should eq(wb.document_id)
    wbs[0].distributor.name.should eq(wb.distributor.name)
    wbs[0].storekeeper.tag.should eq(wb.storekeeper.tag)
    wbs[0].storekeeper_place.tag.should eq(wb.storekeeper_place.tag)
    wbs[0].state.should eq(wb.state)
    wbs[0].sum.should eq(wb.sum)
    wbs[0].resource_tag.should eq(wb.items[0].resource.tag)
    wbs[0].resource_mu.should eq(wb.items[0].resource.mu)
    Converter.float(wbs[0].resource_amount).should eq(wb.items[0].amount)
    Converter.float(wbs[0].resource_price).
            accounting_norm.should eq((1 / wb.items[0].price).accounting_norm)
    Converter.float(wbs[0].resource_sum).
        accounting_norm.should eq((wb.items[0].amount * wb.items[0].price).accounting_norm)

    wbs[1].created.to_s.should eq(wb.created.to_s)
    wbs[1].document_id.should eq(wb.document_id)
    wbs[1].distributor.name.should eq(wb.distributor.name)
    wbs[1].storekeeper.tag.should eq(wb.storekeeper.tag)
    wbs[1].storekeeper_place.tag.should eq(wb.storekeeper_place.tag)
    wbs[1].state.should eq(wb.state)
    wbs[1].sum.should eq(wb.sum)
    wbs[1].resource_tag.should eq(wb.items[1].resource.tag)
    wbs[1].resource_mu.should eq(wb.items[1].resource.mu)
    Converter.float(wbs[1].resource_amount).should eq(wb.items[1].amount)
    Converter.float(wbs[1].resource_price).
        accounting_norm.should eq((1 / wb.items[1].price).accounting_norm)
    Converter.float(wbs[1].resource_sum).
            accounting_norm.should eq((wb.items[1].amount * wb.items[1].price).
                                          accounting_norm)

    wbs[2].created.to_s.should eq(wb2.created.to_s)
    wbs[2].document_id.should eq(wb2.document_id)
    wbs[2].distributor.name.should eq(wb2.distributor.name)
    wbs[2].storekeeper.tag.should eq(wb2.storekeeper.tag)
    wbs[2].storekeeper_place.tag.should eq(wb2.storekeeper_place.tag)
    wbs[2].state.should eq(wb2.state)
    wbs[2].sum.should eq(wb2.sum)
    wbs[2].resource_tag.should eq(wb2.items[0].resource.tag)
    wbs[2].resource_mu.should eq(wb2.items[0].resource.mu)
    Converter.float(wbs[2].resource_amount).should eq(wb2.items[0].amount)
    Converter.float(wbs[2].resource_price).
        accounting_norm.should eq((1 / wb2.items[0].price).accounting_norm)
    Converter.float(wbs[2].resource_sum).
        accounting_norm.should eq((wb2.items[0].amount * wb2.items[0].price).
                                      accounting_norm)
  end


  it 'should sort waybills with resources' do
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
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 2, price: 220.0)
    wb2.save!

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 2,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'briks', mu: 't', amount: 3, price: 10.0)
    wb3.save!
    wb3.apply

    wbs = WaybillReport.order_by(field: 'created', type: 'asc').all
    wbs_test = WaybillReport.order('created').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'created', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('created DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'document_id', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order('document_id').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'document_id', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('document_id DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'distributor', type: 'asc').all
    wbs_test = WaybillReport.joins{deal.rules.from.entity(LegalEntity)}.
        order('legal_entities.name').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.order_by(field: 'distributor', type: 'desc').all
    wbs_test = WaybillReport.joins{deal.rules.from.entity(LegalEntity)}.
        order('legal_entities.name DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.order_by(field: 'storekeeper', type: 'asc').all
    wbs_test = WaybillReport.joins{deal.entity(Entity)}.order('entities.tag').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.order_by(field: 'storekeeper', type: 'desc').all
    wbs_test = WaybillReport.joins{deal.entity(Entity)}.order('entities.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.order_by(field: 'storekeeper_place', type: 'asc').all
    wbs_test = WaybillReport.joins{deal.take.place}.order('places.tag').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.order_by(field: 'storekeeper_place', type: 'desc').all
    wbs_test = WaybillReport.joins{deal.take.place}.order('places.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_tag', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order('assets.tag').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_tag', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('assets.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_mu', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order('assets.mu').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_mu', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('assets.mu DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_amount', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order('rules.rate').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_amount', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('rules.rate DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_price', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order('resource_price').all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_price', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order('resource_price DESC').all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_sum', type: 'asc').all
    wbs_test = WaybillReport.select_all.with_resources.order("resource_sum").all
    wbs.should eq(wbs_test)
    wbs = WaybillReport.select_all.with_resources.order_by(field: 'resource_sum', type: 'desc').all
    wbs_test = WaybillReport.select_all.with_resources.order("resource_sum DESC").all
    wbs.should eq(wbs_test)
  end

  it 'should filter waybills with resources' do
    moscow = create(:place, tag: 'Moscow2')
    kiev = create(:place, tag: 'Kiev2')
    amsterdam = create(:place, tag: 'Amsterdam2')
    ivanov = create(:entity, tag: 'Ivanov2')
    petrov = create(:entity, tag: 'Petrov2')
    antonov = create(:entity, tag: 'Antonov2')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 11,
                distributor: petrov, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 200, price: 220.0)
    wb1.save
    wb1.apply
    wb1 = build(:waybill, created: Date.new(2011,12,01), document_id: 12,
                distributor: ivanov, storekeeper: antonov,
                storekeeper_place: kiev)
    wb1.add_item(tag: 'res', mu: 'mm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'kg', amount: 100, price: 120.0)
    wb1.save
    wb1.apply
    wb1 = build(:waybill, created: Date.new(2011,12,22), document_id: 22,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb1.add_item(tag: 'bricks', mu: 'tt', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'kg', amount: 100, price: 120.0)
    wb1.save
    wb1.apply

    wbs = WaybillReport.search(created: '12').all
    wbs_test = WaybillReport.where{to_char(created, "YYYY-MM-DD").like('%12%')}.all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.search('document_id' => '1').all
    wbs_test = WaybillReport.select_all.with_resources.where("document_id LIKE '%1%'").all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.search('distributor' => 'a').all
    wbs_test = WaybillReport.joins{deal.rules.from.entity(LegalEntity)}.
        where{lower(deal.rules.from.entity.name).like(lower('%a%'))}.all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.search('storekeeper' => 'a').all
    wbs_test = WaybillReport.joins{deal.entity(Entity)}.
        where{lower(deal.entity.tag).like(lower('%a%'))}.all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.search('storekeeper_place' => 'm').all
    wbs_test = WaybillReport.joins{deal.take.place}.
        where{lower(deal.take.place.tag).like(lower('%m%'))}.all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.search('state' => '1').all
    wbs_test = WaybillReport.select_all.with_resources.joins{deal.deal_state}.
        joins{deal.to_facts.outer}.where("deal_states.closed IS NULL").all
    wbs.should eq(wbs_test)

    wbs = WaybillReport.select_all.with_resources.search('resource_tag' => 'r').all
    wbs_test = WaybillReport.select_all.with_resources.
        where{lower(deal.rules.from.take.resource.tag).like(lower('%r%'))}.all
    wbs.should eq(wbs_test)
  end
end
