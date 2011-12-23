# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "single page application", %q{
  As an user
  I want to work with single page
} do

  scenario "visit home page" do
    user = Factory(:user, :password => "somepass")
    page_login(user.email, "somepass")
    visit home_index_path
    current_path.should eq(home_index_path)
    page.should have_content(user.entity.tag)
    page.should have_content("Logout")
    page.should have_content("Inbox")
    page.should have_content("Starred")
    page.should have_content("Drafts")
    page.should have_content("Sent")
    page.should have_content("Trash")
    page.should have_content("Archive")
  end

end
