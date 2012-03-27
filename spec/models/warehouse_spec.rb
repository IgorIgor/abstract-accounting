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
    Factory(:chart)
    moscow = Factory(:place, tag: 'Moscow')
    minsk = Factory(:place, tag: 'Minsk')
    ivanov = Factory(:entity, tag: 'Ivanov')
    petrov = Factory(:entity, tag: 'Petrov')
    wb = Factory.build(:waybill, storekeeper: ivanov,
                                 storekeeper_place: moscow)
    wb.add_item('roof', 'rm', 100, 120.0)
    wb.add_item('nails', 'pcs', 700, 1.0)
    wb.save!
    wb = Factory.build(:waybill, storekeeper: ivanov,
                                 storekeeper_place: moscow)
    wb.add_item('nails', 'pcs', 1200, 1.0)
    wb.add_item('nails', 'kg', 10, 150.0)
    wb.add_item('roof', 'rm', 50, 100.0)
    wb.save!
    wb = Factory.build(:waybill, storekeeper: petrov,
                                 storekeeper_place: minsk)
    wb.add_item('roof', 'rm', 500, 120.0)
    wb.add_item('nails', 'kg', 300, 150.0)
    wb.save!

    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 150) &&
                   (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1900) &&
                   (w.mu == 'pcs') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .empty?.should be_false

    ds_moscow = Factory.build(:distribution, storekeeper: ivanov,
                                             storekeeper_place: moscow)
    ds_moscow.add_item('nails', 'pcs', 510)
    ds_moscow.add_item('roof', 'rm', 7)
    ds_moscow.save!
    ds_minsk = Factory.build(:distribution, storekeeper: petrov,
                                            storekeeper_place: minsk)
    ds_minsk.add_item('roof', 'rm', 500)
    ds_minsk.add_item('nails', 'kg', 85)
    ds_minsk.save!

    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 215) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') && (w.mu == 'rm') &&
                   (w.real_amount == 500) } .empty?.should be_true

    ds_minsk.cancel
    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 150) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1900) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .empty?.should be_false

    ds_moscow.apply
    wh = Warehouse.all
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
                   (w.real_amount == 143) && (w.exp_amount == 143) &&
                   (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 1390) && (w.exp_amount == 1390) &&
                   (w.mu == 'pcs') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
                   (w.real_amount == 10) && (w.exp_amount == 10) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
                   (w.real_amount == 300) && (w.exp_amount == 300) &&
                   (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
                   (w.real_amount == 500) && (w.exp_amount == 500) &&
                   (w.mu == 'rm') } .empty?.should be_false

    wh = Warehouse.all(storekeeper_id: ivanov.id, place_id: moscow.id)
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .empty?.should be_true

    wh = Warehouse.all(storekeeper_id: petrov.id, place_id: minsk.id)
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .empty?.should be_false
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .empty?.should be_false

    wh = Warehouse.all(storekeeper_id: petrov.id, place_id: moscow.id)
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'roof') &&
        (w.real_amount == 143) && (w.exp_amount == 143) &&
        (w.mu == 'rm') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 1390) && (w.exp_amount == 1390) &&
        (w.mu == 'pcs') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Moscow') && (w.tag == 'nails') &&
        (w.real_amount == 10) && (w.exp_amount == 10) &&
        (w.mu == 'kg') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'roof') &&
        (w.real_amount == 500) && (w.exp_amount == 500) &&
        (w.mu == 'rm') } .empty?.should be_true
    wh.select{ |w| (w.place == 'Minsk') && (w.tag == 'nails') &&
        (w.real_amount == 300) && (w.exp_amount == 300) &&
        (w.mu == 'kg') } .empty?.should be_true
  end
end
