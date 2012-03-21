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
  end

  it 'should create items' do
    Factory(:chart)

    wb = Factory.build(:waybill)
    wb.add_item('nails', 'pcs', 1200, 1.0)
    wb.add_item('nails', 'kg', 10, 150.0)
    wb.save!

    db = Factory.build(:distribution)
    db.add_item("nails", "pcs", 500)
    db.add_item("nails", "kg", 2)
    db.items.count.should eq(2)
  end
end
