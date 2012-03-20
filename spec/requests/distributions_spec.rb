# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'distributions', %q{
  As an user
  I want to view distributions
} do

  scenario 'view distributions', js: true do
    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/distributions/new']").click
    current_hash.should eq('documents/distributions/new')
  end
end
