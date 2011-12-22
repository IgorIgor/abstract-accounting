# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

feature "Login", %q{
  As an user
  I can login
} do

  def page_login(email, password)
    fill_in("Email", :with => email)
    fill_in("Password", :with => password)
    click_on "Log in"
  end

  scenario "login" do
    visit home_index_path
    current_path.should eq(login_path)
    page.should have_content("Email")
    page.should have_content("Password")

    User.delete_all
    page_login("root@localhost", Settings.root.password)
    current_path.should eq(root_path)
    click_on "Logout"
    current_path.should eq(login_path)

    user = Factory(:user, :password => "somepass")
    page_login user.email ,"somepass_fail"
    page.should have_content("Email or password was invalid.")
    current_path.should eq(login_path)

    page_login user.email ,"somepass"
    current_path.should eq(root_path)
  end

end
