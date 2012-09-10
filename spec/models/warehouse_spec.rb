# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Warehouse do
  it 'should show warehouse items' do
    create(:chart)
    moscow = create(:place, tag: 'Moscow')
    minsk = create(:place, tag: 'Minsk')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')
    wb = build(:waybill, storekeeper: ivanov,
                                 storekeeper_place: moscow)
    wb.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb.save!
    wb.apply
    wb = build(:waybill, storekeeper: ivanov,
                                 storekeeper_place: moscow)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb.save!
    wb.apply
    wb = build(:waybill, storekeeper: petrov,
                                 storekeeper_place: minsk)
    wb.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb.save!
    wb.apply

    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 150) &&
                   (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1900) &&
                   (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .should_not be_empty
    Warehouse.count.should eq(wh.count)

    ds_moscow = build(:allocation, storekeeper: ivanov,
                                   storekeeper_place: moscow)
    ds_moscow.add_item(tag: 'nails', mu: 'pcs', amount: 510)
    ds_moscow.add_item(tag: 'roof', mu: 'rm', amount: 7)
    ds_moscow.save!
    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 500)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 85)
    ds_minsk.save!

    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 215) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') && (w.mu == 'rm') &&
                   (w.real_amount == 500) } .should be_empty
    Warehouse.count.should eq(wh.count)

    ds_minsk.cancel
    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .should_not be_empty
    Warehouse.count.should eq(wh.count)

    ds_moscow.apply
    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 143) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1390) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .should_not be_empty
    Warehouse.count.should eq(wh.count)

    wh = Warehouse.all(where: { warehouse_id: { equal: moscow.id } })
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { warehouse_id: { equal: moscow.id }}).should eq(wh.count)

    wh = Warehouse.all(where: { warehouse_id: { equal: minsk.id }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should_not be_empty
    Warehouse.count(where: { warehouse_id: { equal: minsk.id } }).should eq(wh.count)

    per_page = Warehouse.all.count - 1
    wh = Warehouse.all(page: 1, per_page: per_page)
    wh.count.should eq(per_page)

    wh = Warehouse.all(page: 2, per_page: per_page)
    wh.count.should eq(1)

    wh = Warehouse.all(where: { place: { like: 'mo' }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { place: { like: 'mo' }}).should eq(wh.count)

    wh = Warehouse.all(where: { place: { like: 'mo' },
                                tag: { like: 'ai' }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { place: { like: 'mo' },
                             tag: { like: 'ai' }}).should eq(wh.count)

    wh = Warehouse.all(where: { place: { like: 'mo' },
                                tag: { like: 'ai' },
                                real_amount: { like: '13' }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should_not be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { place: { like: 'mo' },
                             tag: { like: 'ai' },
                             real_amount: { like: '13' }}).should eq(wh.count)

    wh = Warehouse.all(where: { place: { like: 'mo' },
                                tag: { like: 'ai' },
                                exp_amount: { like: '10' }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { place: { like: 'mo' },
                             tag: { like: 'ai' },
                             exp_amount: { like: '10' }}).should eq(wh.count)

    wh = Warehouse.all(where: { place: { like: 'mo' },
                                tag: { like: 'ai' },
                                mu: { like: 'k' }})
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { place: { like: 'mo' },
                             tag: { like: 'ai' },
                             mu: { like: 'k' }}).should eq(wh.count)

    wh = Warehouse.all(where: { warehouse_id: { equal: minsk.id }},
                       without: [ Asset.find_by_tag_and_mu('nails', 'kg').id ])
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should_not be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { warehouse_id: { equal: minsk.id }},
                    without: [ Asset.find_by_tag_and_mu('nails', 'kg').id ])
      .should eq(wh.count)

    wh = Warehouse.all(where: { warehouse_id: { equal: minsk.id }},
                       without: [ Asset.find_by_tag_and_mu('nails', 'kg').id,
                                  Asset.find_by_tag_and_mu('roof', 'rm').id ])
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .should be_empty
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .should be_empty
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .should be_empty
    Warehouse.count(where: { warehouse_id: { equal: minsk.id }},
                    without: [ Asset.find_by_tag_and_mu('nails', 'kg').id,
                               Asset.find_by_tag_and_mu('roof', 'rm').id ])
      .should eq(wh.count)

    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 200)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 85)
    ds_minsk.save!

    Warehouse.all(where: { warehouse_id: { equal: minsk.id },
                           'assets.id' => { equal_attr: Asset.find_by_tag_and_mu('nails', 'kg').id } })
             .first.exp_amount.to_i.should eq(215)
    Warehouse.all(where: { warehouse_id: { equal: minsk.id },
                           'assets.id' => { equal_attr: Asset.find_by_tag_and_mu('roof', 'rm').id } })
             .first.exp_amount.to_i.should eq(300)
    wb.items.first.exp_amount.should eq(300)
    wb.items.last.exp_amount.should eq(215)

    wh = Warehouse.group({group_by: 'place'})
    wh.select{ |w| (w[:value] == 'Moscow') &&
        (w[:id] == moscow.id) }.should_not be_empty
    wh.select{ |w| (w[:value] == 'Minsk') &&
        (w[:id] == minsk.id) }.should_not be_empty
    Warehouse.count({group_by: 'place'}).should eq(wh.length)

    wh = Warehouse.group({group_by: 'tag'})
    resorce = Asset.find_by_tag_and_mu('roof', 'rm')
    wh.select{ |w| (w[:value] == resorce.tag) &&
        (w[:id] == resorce.id) }.should_not be_empty
    resorce = Asset.find_by_tag_and_mu('nails', 'pcs')
    wh.select{ |w| (w[:value] == resorce.tag) &&
        (w[:id] == resorce.id) }.should_not be_empty
    resorce = Asset.find_by_tag_and_mu('nails', 'kg')
    wh.select{ |w| (w[:value] == resorce.tag) &&
        (w[:id] == resorce.id) }.should_not be_empty
    Warehouse.count({group_by: 'tag'}).should eq(wh.length)

    wh = Warehouse.all(order_by: { field: 'place', type: 'asc' })
    (wh.count - 1).times do |i|
      wh[i].place.should be <= wh[i + 1].place
    end
    wh = Warehouse.all(order_by: { field: 'place', type: 'desc' })
    (wh.count - 1).times do |i|
      wh[i].place.should be >= wh[i + 1].place
    end

    wh = Warehouse.all(order_by: { field: 'tag', type: 'asc' })
    (wh.count - 1).times do |i|
      wh[i].tag.should be <= wh[i + 1].tag
    end
    wh = Warehouse.all(order_by: { field: 'tag', type: 'desc' })
    (wh.count - 1).times do |i|
      wh[i].tag.should be >= wh[i + 1].tag
    end

    wh = Warehouse.all(order_by: { field: 'mu', type: 'asc' })
    (wh.count - 1).times do |i|
      wh[i].mu.should be <= wh[i + 1].mu
    end
    wh = Warehouse.all(order_by: { field: 'mu', type: 'desc' })
    (wh.count - 1).times do |i|
      wh[i].mu.should be >= wh[i + 1].mu
    end

    wh = Warehouse.all(order_by: { field: 'real_amount', type: 'asc' })
    (wh.count - 1).times do |i|
      wh[i].real_amount.should be <= wh[i + 1].real_amount
    end
    wh = Warehouse.all(order_by: { field: 'real_amount', type: 'desc' })
    (wh.count - 1).times do |i|
      wh[i].real_amount.should be >= wh[i + 1].real_amount
    end

    wh = Warehouse.all(order_by: { field: 'exp_amount', type: 'asc' })
    (wh.count - 1).times do |i|
      wh[i].exp_amount.should be <= wh[i + 1].exp_amount
    end
    wh = Warehouse.all(order_by: { field: 'exp_amount', type: 'desc' })
    (wh.count - 1).times do |i|
      wh[i].exp_amount.should be >= wh[i + 1].exp_amount
    end
  end
end
