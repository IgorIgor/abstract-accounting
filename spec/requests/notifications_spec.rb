# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

feature 'notifications', %q{
  As an user
  I want to view notifications
} do

  before :each do
    create :chart
  end

  scenario 'create new notification', js: true do
    3.times { create :user }

    page_login
    click_link I18n.t('views.home.notification')
    current_hash.should eq 'documents/notifications/new'
    click_button I18n.t('views.user_notification.send')
    within "#container_documents form" do
      find("#container_notification").visible?.should be_true
      within "#container_notification" do
        page.should have_content("#{I18n.t(
          'views.user_notification.title')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
          'views.user_notification.message')} : #{I18n.t('errors.messages.blank')}")
      end
    end
    fill_in('title', with: 'new notification')
    fill_in('message', with: 'message of notification')

    expect {
      click_button I18n.t('views.user_notification.send')
      wait_for_ajax
      wait_until_hash_changed_to "documents/notifications/#{Notification.last.id}"
    }.to change(Notification, :count).by(1) &&
         change(NotifiedUser, :count).by(User.count)

    find_button(I18n.t('views.user_notification.send'))[:disabled].should eq('true')
    find_field('title')[:disabled].should eq('true')
    find_field('message')[:disabled].should eq('true')
    find_field('date')[:disabled].should eq('true')
    find_field('title')[:value].should eq('new notification')
    find_field('message')[:value].should eq('message of notification')
    find_field('date')[:value].should eq(Notification.last.date.strftime('%Y/%m/%d'))
  end
end
