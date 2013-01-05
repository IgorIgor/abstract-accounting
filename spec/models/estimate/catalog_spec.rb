# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Catalog do
  it "should have next behaviour" do
    create(:catalog)
    should validate_presence_of :tag
    should validate_uniqueness_of(:tag).scoped_to(:parent_id)
    should belong_to(:parent).class_name(Estimate::Catalog)
    should belong_to :document
    should have_many(:subcatalogs).class_name(Estimate::Catalog)
    should have_many Estimate::Catalog.versions_association_name
    should have_many(:boms).class_name(Estimate::BoM)
    should have_many(:prices)
  end

  it "should create or update catalog" do
    catalog = create(:catalog)
    catalog.document.should be_nil
    catalog.create_or_update_document({title: "HAHA", data: "<h1>aaaa</h1>"})
    catalog.document.should_not be_nil
    catalog.document.title.should eq("HAHA")
    catalog.document.data.should eq("<h1>aaaa</h1>")
    catalog.create_or_update_document({title: "HAHA1", data: "<h1>aaaa1</h1>"})
    catalog.document.should_not be_nil
    catalog.document.title.should eq("HAHA1")
    catalog.document.data.should eq("<h1>aaaa1</h1>")
  end

  it "should filtrate by parent_id" do
    parent = create(:catalog)
    catalog = create(:catalog, parent_id: parent.id)
    Estimate::Catalog.with_parent_id(parent.id).should =~ Estimate::Catalog.
        where{parent_id == my{parent.id}}
  end
end
