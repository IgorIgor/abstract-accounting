# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "rspec"
require 'spec_helper'

describe SqlBuilder do

  it "should build sql-string for paginate" do
    SqlBuilder.paginate({page: 1, per_page: 10}).should eq('LIMIT 10 OFFSET 0')
    SqlBuilder.paginate({page: 2, per_page: 10}).should eq('LIMIT 10 OFFSET 10')
    SqlBuilder.paginate({page: 1}).
        should eq("LIMIT #{Settings.root.per_page} OFFSET 0")
    SqlBuilder.paginate({per_page: 10}).should eq('')
    SqlBuilder.paginate({}).should eq('')
  end
end
