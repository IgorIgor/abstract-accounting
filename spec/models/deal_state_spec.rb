# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe DealState do
  it "should have next behaviour" do
    d = DealState.new(open: Date.today)
    d.deal = create(:deal)
    d.save!
    should validate_presence_of :open
    should validate_uniqueness_of :deal_id
    should belong_to :deal
  end
end
