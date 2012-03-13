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
  it "should have next behaviour" do
    Factory(:waybill)
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
  end

  describe "#items" do
    it "should create" do
      waybill = Factory.build(:waybill)
      waybill.add_item("nails", "pcs", 1200, 1.0)
      waybill.add_item("nails", "kg", 10, 150.0)
      lambda { waybill.save } .should change(Asset, :count).by(2)
      waybill.items.count.should eq(2)

      asset = Factory(:asset)
      waybill.add_item(asset.tag, asset.mu, 100, 12.0)
      lambda { waybill.save } .should_not change(Asset, :count)
      waybill.items.count.should eq(3)
    end
  end
end
