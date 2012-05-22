# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "group", %q{
  As an user
  I want to create groups
}do

  scenario "create groups", js: true do
    2.times { create(:user) }
    page_login

    page.find('#btn_create').click
    page.find("a[@href='#documents/groups/new']").click
    page.should have_xpath("//ul[@id='documents_list' and "+
                               " contains(@style, 'display: none')]")

    current_hash.should eq('documents/groups/new')
    page.should have_selector("div[@id='container_documents'] form")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")
    click_button(I18n.t('views.groups.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.groups.tag')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.groups.manager')} : #{I18n.t('errors.messages.blank')}")
      end
      fill_in('group_tag', with: 'group#1')
      check_autocomplete('group_manager',
        User.joins(:entity).order("entities.tag").limit(5).select("entities.tag as tag").all,
        :tag, true)
      fill_in_autocomplete('group_manager', User.first.entity.tag)

      click_button(I18n.t('views.groups.add'))
      within("fieldset table tbody") do
        page.should have_selector('tr', count: 1)
      end
    end
    click_button(I18n.t('views.groups.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.groups.user_name')}#0 #{I18n.t(
            'views.groups.user')} : #{I18n.t('errors.messages.blank')}")

      end
      within("fieldset table tbody") do
        fill_in_autocomplete("user_0", User.last.entity.tag)
      end
    end

    lambda do
      click_button(I18n.t('views.groups.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(Group, :count).by(1)
  end
end
