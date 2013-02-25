# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Document do
  it "should have next behaviour" do
    Estimate::Document.create! title: "catalog0", data: "dsaasdasd"
    should validate_presence_of :title
    should validate_presence_of :data
    should validate_uniqueness_of :title
    should have_one :catalog
    should have_many Estimate::Document.versions_association_name
  end
end
