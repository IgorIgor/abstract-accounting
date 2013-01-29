# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::LocalElement do
  it "should have next behaviour" do
    Estimate::LocalElement.create!(:local_id => 0, :price_list_id => 0, :amount => 10)
    should validate_presence_of :price_list_id
    should validate_presence_of :amount
    should validate_uniqueness_of(:price_list_id).scoped_to(:local_id)
    should belong_to :estimate
    should belong_to(:price_list).class_name(Estimate::PriceList)
    should have_many Estimate::LocalElement.versions_association_name
  end
end
