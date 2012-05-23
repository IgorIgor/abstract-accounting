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

  scenario "show all groups", js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times do
      create(:group)
    end
    groups = Group.limit(per_page).all
    count = Group.count
    page_login
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//div[@id='sidebar']/ul/li[@id='groups'" +
                               " and @class='sidebar-selected']")

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.groups.tag'))
        page.should have_content(I18n.t('views.groups.manager'))
      end

      within('tbody') do
        groups.each do |group|
          page.should have_content(group.tag)
          page.should have_content(group.manager.entity.tag)
        end
      end
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")
      find("span[@data-bind='text: count']").should have_content(count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    within("div[@class='paginate']") do
      click_button('>')
      to_range = count > (per_page * 2) ? per_page * 2 : count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")
      find("span[@data-bind='text: count']").should have_content(count.to_s)

      find_button('<')[:disabled].should eq('false')
    end

    groups = Group.limit(per_page).offset(per_page).all
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page
      page.should have_selector('tr', count: count_on_page)
      groups.each do |group|
        page.should have_content(group.tag)
        page.should have_content(group.manager.entity.tag)
      end
    end

    within("div[@class='paginate']") do
      click_button('<')

      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end
  end

  scenario "show group", js: true do
    group = Group.count > 0 ? Group.first : create(:group)
    if group.users(:force_update).empty?
      2.times { group.users << create(:user) }
    end
    page_login
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//div[@id='sidebar']/ul/li[@id='groups'" +
                               " and @class='sidebar-selected']")
    within('#container_documents table') do
      find(:xpath, ".//tbody//tr[1]//td["+
          "contains(.//text(), '#{group.manager.entity.tag}')]").click
    end
    current_hash.should eq("documents/groups/#{group.id}")
    find("#group_tag")[:disabled].should eq('true')
    find("#group_manager")[:disabled].should eq('true')
    find_button(I18n.t('views.groups.add'))[:disabled].should eq('true')
    find_button(I18n.t('views.groups.save'))[:disabled].should eq('true')

    find("#group_tag")[:value].should eq(group.tag)
    find("#group_manager")[:value].should eq(group.manager.entity.tag)

    within("fieldset table tbody") do
      group.users(:force_update).each_with_index do |u, i|
        within(:xpath, ".//tr[#{i + 1}]") do
          find(:xpath, ".//td//input[@type='text']")[:value].should eq(u.entity.tag)
          find(:xpath, ".//td//input[@type='text']")[:disabled].should eq("true")
        end
      end
    end
  end
end
