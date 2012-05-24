# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Comment do
  it 'should have next behaviour' do
    should validate_presence_of :user
    should validate_presence_of :item
    should belong_to :user
    should belong_to :item
  end
end
