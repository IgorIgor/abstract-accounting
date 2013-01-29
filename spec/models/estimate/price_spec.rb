# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Price do
  it "should have next behaviour" do
    should validate_presence_of :date
    should validate_presence_of :bo_m_id
    should validate_presence_of :direct_cost
    should validate_presence_of :catalog_id

    should validate_uniqueness_of(:date).scoped_to(:catalog_id, :bo_m_id)

    should belong_to(:bo_m).class_name(Estimate::BoM)
    should belong_to :catalog
    should have_many(Estimate::Price.versions_association_name)

    should delegate_method(:uid).to(:bo_m)
    should delegate_method(:tag).to(:bo_m)
    should delegate_method(:mu).to(:bo_m)

    should delegate_method(:resource).to(:bo_m)
  end

  it "should filter by catalog_id" do
    10.times { create(:price) }
    catalog = create(:catalog)
    price = create(:price, catalog: catalog)
    Estimate::Price.with_catalog_id(catalog.id).should =~ Estimate::Price.
        where{catalog_id == my{catalog.id}}
  end

  it 'should sort prices' do
    10.times { create(:price) }

    pls = Estimate::Price.sort(field: "date", type: "asc").all
    test_pls = Estimate::Price.order("date").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_uid("asc").all
    test_pls = Estimate::Price.joins{bo_m}.order("estimate_bo_ms.uid").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_tag("asc").all
    test_pls = Estimate::Price.joins{bo_m.resource}.order("assets.tag").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_mu("asc").all
    test_pls = Estimate::Price.joins{bo_m.resource}.order("assets.mu").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_catalog_tag("asc").all
    test_pls = Estimate::Price.joins{catalog}.order("estimate_catalogs.tag").all
    pls.should eq(test_pls)

    pls = Estimate::Price.sort(field: "date", type: "desc").all
    test_pls = Estimate::Price.order("date desc").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_uid("desc")
    test_pls = Estimate::Price.joins{bo_m}.order("estimate_bo_ms.uid desc").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_tag("desc")
    test_pls = Estimate::Price.joins{bo_m.resource}.order("assets.tag desc").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_mu("desc")
    test_pls = Estimate::Price.joins{bo_m.resource}.order("assets.mu desc").all
    pls.should eq(test_pls)
    pls = Estimate::Price.sort_by_catalog_tag("desc")
    test_pls = Estimate::Price.joins{catalog}.order("estimate_catalogs.tag desc").all
    pls.should eq(test_pls)
  end
end
