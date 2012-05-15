# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Credential do
  it "should have next behaviour" do
    create(:credential)
    should validate_presence_of :user_id
    should validate_uniqueness_of(:document_type).scoped_to(:user_id, :place_id)
    should belong_to :user
    should belong_to :place
    should have_many Credential.versions_association_name
  end
end
