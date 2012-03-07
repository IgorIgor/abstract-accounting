# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Waybill do
  it "should have next behaviour" do
    Factory(:waybill)
    should validate_presence_of :document_id
    should validate_presence_of :legal_entity_id
    should validate_presence_of :place_id
    should validate_presence_of :entity_id
    should validate_presence_of :created
    should validate_uniqueness_of :document_id
    should belong_to :legal_entity
    should belong_to :place
    should belong_to :entity
  end
end
