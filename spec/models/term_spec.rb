# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Term do
  it "should have next behaviour" do
    create(:term, :deal_id => 0)
    should validate_presence_of :deal_id
    should validate_presence_of :resource_id
    should validate_uniqueness_of(:deal_id).scoped_to(:side)
    should belong_to :deal
    should belong_to :place
    should belong_to(:type).class_name(Classifier)
    should belong_to :resource
  end
end
