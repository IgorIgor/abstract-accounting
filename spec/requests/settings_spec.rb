# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'settings', %q{
  As an user
  I want to view settings
} do

  scenario 'view settings page and enter currency settings', js: true do
    Chart.delete_all if Chart.count != 0
    create(:money, alpha_code: 'aaa', num_code: 1122)

    page_login
    current_hash.should eq('settings/new')
    page.should_not have_selector("#inbox[@class='sidebar-selected']")

    within('#container_documents') do
      page.should have_xpath("//span[@id='page-title']")
      page.should have_xpath("//input[@id='money_alpha_code']")
      page.should have_xpath("//input[@id='money_num_code']")

      click_button(I18n.t('views.settings.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t('views.settings.tag')} : #{I18n.t(
            'errors.messages.blank')}")
        page.should have_content("#{I18n.t('views.settings.code')} : #{I18n.t(
            'errors.messages.blank')}")
      end

      fill_in('money_alpha_code', with: 'aaa')
      fill_in('money_num_code', with: '12345')
      click_button(I18n.t('views.settings.save'))
      click_button(I18n.t('views.settings.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification ul") do
        page.should have_selector('li', count: 1)
      end

      fill_in('money_alpha_code', with: 'Some Currency')
      fill_in('money_num_code', with: '12345')

      lambda do
        page.find(:xpath, "//div[@class='actions']" +
            "//input[@value='#{I18n.t('views.settings.save')}']").click
        current_hash.should eq('inbox')
        page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")
      end.should change(Chart, :count).by(1)
    end
  end

  scenario 'show current settings', js: true do
    create(:chart)
    page_login
    current_hash.should eq('inbox')
    page.should have_selector("#inbox[@class='sidebar-selected']")
    click_link I18n.t('views.home.settings')
    current_hash.should eq('settings')
    page.should_not have_selector("#inbox[@class='sidebar-selected']")
    page.should have_xpath("//span[@id='page-title']")
    find('#money_alpha_code')[:disabled].should eq('true')
    find('#money_num_code')[:disabled].should eq('true')
    find_button(I18n.t('views.settings.save'))[:disabled].should eq('true')

    money = Chart.first.currency
    find("#money_alpha_code")[:value].should eq(money.alpha_code)
    find("#money_num_code")[:value].should eq(money.num_code.to_s)
  end
end
