# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Base do
  it "should have next behavior" do
    Estimate::Base.abstract_class.should be_true
    Estimate::Base.table_name_prefix.should eq("estimate_")
  end
end
