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

    3.times do |i|
      create :user
      n = Notification.create(title: "new#{i}", message: "msg#{i}",
                              notification_type: 1, date: DateTime.now - 10 + i)
      n.assign_users
    end
  end

  scenario 'create new notification', js: true do
    page_login
    click_link I18n.t('views.home.notify')
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
      wait_until_hash_changed_to "documents/notifications/#{Notification.first.id}"
    }.to change(Notification, :count).by(1) &&
         change(NotifiedUser, :count).by(User.count)

    find_button(I18n.t('views.user_notification.send'))[:disabled].should eq('true')
    find_field('title')[:disabled].should eq('true')
    find_field('message')[:disabled].should eq('true')
    find_field('date')[:disabled].should eq('true')
    find_field('title')[:value].should eq('new notification')
    find_field('message')[:value].should eq('message of notification')
    find_field('date')[:value].should eq(Notification.first.date.strftime('%Y/%m/%d'))
  end

  scenario 'view notifications for root_user', js: true do
    page_login
    click_link I18n.t('views.home.notifications')
    current_hash.should eq 'notifications'
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 3)
      Notification.all.each do |item|
        page.should have_content(item.date.strftime('%Y/%m/%d'))
        page.should have_content(item.title)
      end
    end
  end

  scenario 'view notifications for user', js: true do
    user = create(:user, email: 'iv@mail.ru', password: '123456')
    Notification.create(title: "note", message: "mes",
                        notification_type: 1, date: DateTime.now).assign_users
    page_login('iv@mail.ru', '123456')
    click_link I18n.t('views.home.notifications')
    current_hash.should eq 'notifications'
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      Notification.joins{notified_users}.
          where{ notified_users.user_id == user.id}.
          order('date DESC').all.each do |item|
        page.should have_content(item.date.strftime('%Y/%m/%d'))
        page.should have_content(item.title)
      end
    end
  end

  scenario 'show notification', js: true do
    page_login
    click_link I18n.t('views.home.notifications')
    find(:xpath, "//div[@id='container_documents']/table/tbody/tr[1]/td[1]").click
    current_hash.should eq "documents/notifications/#{Notification.first.id}"
  end
end
