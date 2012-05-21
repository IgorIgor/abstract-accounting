# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Group do
  it "should have next behaviour" do
    create(:group)
    should validate_presence_of :manager_id
    should validate_presence_of :tag
    should validate_uniqueness_of :tag
    should belong_to(:manager).class_name(User)
    should have_many Group.versions_association_name
    should have_and_belong_to_many(:users)
  end
end
