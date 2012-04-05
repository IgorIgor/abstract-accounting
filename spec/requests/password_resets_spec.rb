# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

feature "Reset password", %q{
  As an user
  I can reset password
} do

  scenario "reset password" do
    user = Factory(:user)

    visit login_path
    click_link I18n.t 'views.user_sessions.reset_password'
    page.should have_content(I18n.t 'views.password_resets.email')
    fill_in("email", :with => user.email)
    click_button I18n.t 'views.password_resets.password_reset'
    page.should have_content(I18n.t 'views.password_resets.notice.instructions_sent')
    current_path.should eq(login_path)

    visit edit_password_reset_path("fail_token")
    current_path.should_not eq(edit_password_reset_path("fail_token"))
    current_path.should eq(login_path)

    user.update_attributes! :reset_password_token => "sometoken",
                            :reset_password_email_sent_at => nil,
                            :password => "somepass",
                            :password_confirmation => "somepass"
    visit edit_password_reset_path(user.reset_password_token)
    page.should have_content(I18n.t 'views.password_resets.email')
    find_field('email').value.should eq(user.email)
    page.should have_content(I18n.t 'views.password_resets.password')
    page.should have_content(I18n.t 'views.password_resets.password_confirmation')
    fill_in("user_password", :with => "changed_pass")
    fill_in("user_password_confirmation", :with => "changed_pass")
    click_button I18n.t 'views.password_resets.update_password'
    page.should have_content(I18n.t 'views.password_resets.notice.password_updated')
    current_path.should eq(login_path)

    visit new_password_reset_path
    click_link I18n.t 'views.password_resets.back'
    current_path.should eq(login_path)

    visit edit_password_reset_path(Factory(:user).reset_password_token)
    fill_in("user_password", :with => "changed_pass")
    fill_in("user_password_confirmation", :with => "fail_pass")
    click_button I18n.t 'views.password_resets.update_password'
    page.should have_content(I18n.t 'views.password_resets.enter_error')
  end

end
