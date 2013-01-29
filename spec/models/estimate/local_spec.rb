# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Local do
  it "should have next behaviour" do
    should validate_presence_of :catalog_id
    should validate_presence_of :date
    should validate_presence_of :tag
    should belong_to(:catalog)
    should have_many Estimate::Local.versions_association_name
    should have_many(:items).class_name(Estimate::LocalElement)
  end

  describe "#items" do
    before(:all) do
      create(:chart)
      @truck = create(:asset)
      @compressor = create(:asset)
      @compaction = create(:asset)
      @covering = create(:asset)
      catalog = Estimate::Catalog.create!(:tag => "TUP of the Leningrad region")
      @estimate = Estimate::Local.create!(:legal_entity => create(:legal_entity),
                                   :catalog => catalog,
                                   :date => DateTime.civil(2011, 11, 01, 12, 0, 0))
    end
  end
end
