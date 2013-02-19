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
    should validate_presence_of :date
    should validate_presence_of :tag
    should validate_presence_of :project_id

    should belong_to :project

    should have_many Estimate::Local.versions_association_name
    should have_many(:items).class_name(Estimate::LocalElement)
  end

  it 'should return uncanceled estimates' do
    10.times { create :local }
    Estimate::Local.first.update_attribute(:canceled, DateTime.now)
    Estimate::Local.without_canceled.should eq Estimate::Local.where{canceled == nil}
  end
end
