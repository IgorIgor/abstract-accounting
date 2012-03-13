# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Service do
  it "should have next behaviour" do
    Service.create!(:tag => "service", :mu => "mu")
    should validate_presence_of :tag
    should validate_presence_of :mu
    should validate_uniqueness_of(:tag).scoped_to(:mu)
    should belong_to(:detailed).class_name(DetailedService)
    should have_many :terms
    should have_many Service.versions_association_name
  end
end
