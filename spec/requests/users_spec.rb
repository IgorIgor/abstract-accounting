# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "user", %q{
  As an user
  I want to create users
}do

  scenario "create users", :js => true do
    page_login

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    current_hash.should eq('documents/users/new')
    page.should have_selector("div[@id='container_documents'] form")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")
    click_button(I18n.t('views.users.save'))


    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.users.user_name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.email')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.password')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.password_confirmation')} : #{I18n.t(
            'errors.messages.blank')}")
      end

      6.times { create(:entity) }
      check_autocomplete("user_entity", Entity.order(:tag).limit(5), :tag)

      fill_in('user_entity', with: 'Kingston Jack')
      fill_in('user_email', with: 'wrong mail')
      fill_in('user_password', with: '1234')
      fill_in('user_password_confirmation', with: '123')
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.users.email')} : #{I18n.t('errors.messages.email')}")
        page.should have_content("#{I18n.t('views.users.password')} : #{
            I18n.t(
            'errors.messages.too_short.few', count: 6)}")
        page.should have_content("#{I18n.t('views.users.password_confirmation')} : #{
            I18n.t(
            'errors.messages.equal_to', value: I18n.t('views.users.password'))}")
      end
    end

    fill_in('user_email', with: 'mymail@gmail.com')
    fill_in('user_password', with: '1234567')
    fill_in('user_password_confirmation', with: '1234567')
    find("#container_notification").visible?.should_not be_true

    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(1) && change(Entity, :count).by(1)

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click

    fill_in('user_entity', with: "Kingston")
    page.should have_xpath("//ul[contains(@class, 'ui-autocomplete')"+
                               " and contains(@style, 'display: block')]")
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
        " and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('user_email', with: 'othermail@gmail.com')
    fill_in('user_password', with: '123123123')
    fill_in('user_password_confirmation', with: '123123123')

    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(1) && change(Entity, :count).by(0)

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click
    click_button(I18n.t('views.users.back'))
    page.should have_selector("#inbox[@class='sidebar-selected']")
  end
end
