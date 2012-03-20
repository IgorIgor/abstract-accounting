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
    wb = Factory.build(:waybill, storekeeper_place: moscow)
    wb.add_item('roof', 'rm', 100, 120.0)
    wb.add_item('nails', 'pcs', 700, 1.0)
    wb.save!
    wb = Factory.build(:waybill, storekeeper: wb.storekeeper,
                                 storekeeper_place: moscow)
    wb.add_item('nails', 'pcs', 1200, 1.0)
    wb.add_item('nails', 'kg', 10, 150.0)
    wb.add_item('roof', 'rm', 50, 100.0)
    wb.save!
    wb = Factory.build(:waybill, storekeeper_place: minsk)
    wb.add_item('roof', 'rm', 500, 120.0)
    wb.add_item('nails', 'kg', 300, 150.0)
    wb.save!

    wh = Warehouse.all
    wh.count.should eq(5)
    wh[0].place.should eq('Moscow')
    wh[0].tag.should eq('roof')
    wh[0].real_amount.should eq(150)
    wh[0].exp_amount.should eq(150)
    wh[0].mu.should eq('rm')
    wh[1].place.should eq('Moscow')
    wh[1].tag.should eq('nails')
    wh[1].real_amount.should eq(1900)
    wh[1].exp_amount.should eq(1900)
    wh[1].mu.should eq('pcs')
    wh[2].place.should eq('Moscow')
    wh[2].tag.should eq('nails')
    wh[2].real_amount.should eq(10)
    wh[2].exp_amount.should eq(10)
    wh[2].mu.should eq('kg')
    wh[3].place.should eq('Minsk')
    wh[3].tag.should eq('roof')
    wh[3].real_amount.should eq(500)
    wh[3].exp_amount.should eq(500)
    wh[3].mu.should eq('rm')
    wh[4].place.should eq('Minsk')
    wh[4].tag.should eq('nails')
    wh[4].real_amount.should eq(300)
    wh[4].exp_amount.should eq(300)
    wh[4].mu.should eq('kg')
  end
end
