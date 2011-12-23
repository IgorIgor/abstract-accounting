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

  scenario "login" do
    visit home_index_path
    current_path.should eq(login_path)
    page.should have_content("Email")
    page.should have_content("Password")

    User.delete_all
    page_login
    current_path.should eq(root_path)
    click_on "Logout"
    current_path.should eq(login_path)

    user = Factory(:user, :password => "somepass")
    page_login user.email ,"somepass_fail"
    page.should have_content("Email or password was invalid.")
    current_path.should eq(login_path)

    page_login user.email ,"somepass"
    current_path.should eq(root_path)
    click_on "Logout"
  end

  scenario "remember user" do
    user = User.first
    visit home_index_path
    page_login(user.email, "somepass")
    RackTestBrowser.new.restart
    visit home_index_path
    current_path.should eq(login_path)

    page_login(user.email, "somepass", true)
    RackTestBrowser.new.restart
    visit home_index_path
    current_path.should eq(home_index_path)
    click_on "Logout"

    page_login("root@localhost", Settings.root.password, true)
    RackTestBrowser.new.restart
    visit home_index_path
    current_path.should eq(login_path)
  end
end

class RackTestBrowser
  def initialize
    @driver = Capybara.current_session.driver
  end

  def restart
    self.cookies.reject! do |cookie|
      cookie.expired? != false
    end
  end

  def cookies
    @cookies ||= self.cookie_jar.instance_variable_get(:@cookies)
  end

  def cookie_jar
    @cookie_jar ||= self.browser.cookie_jar
  end

  def browser
    @browser ||= self.session.instance_variable_get(:@rack_mock_session)
  end

  def session
    @session ||= @driver.browser.current_session
  end
end
