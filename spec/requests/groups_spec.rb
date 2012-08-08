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

  before :each do
    create(:chart)
  end

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
      wait_for_ajax
      wait_until_hash_changed_to "documents/groups/#{Group.last.id}"
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
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
     	                     "//li[@id='groups' and @class='sidebar-selected']")

    titles = [I18n.t('views.groups.tag'), I18n.t('views.groups.manager')]

    check_header("#container_documents table", titles)
    check_content("#container_documents table", groups) do |group|
      [group.tag, group.manager.entity.tag]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    groups = Group.limit(per_page).offset(per_page).all
    check_content("#container_documents table", groups) do |group|
      [group.tag, group.manager.entity.tag]
    end
  end

  scenario "show group", js: true do
    group = Group.count > 0 ? Group.first : create(:group)
    if group.users(:force_update).empty?
      2.times { group.users << create(:user) }
    end
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
     	                     "//li[@id='groups' and @class='sidebar-selected']")
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

  scenario "edit group", js: true do
    group = Group.count > 0 ? Group.first : create(:group)
    if group.users(:force_update).empty?
      2.times { group.users << create(:user) }
    end
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
     	                     "//li[@id='groups' and @class='sidebar-selected']")
    within('#container_documents') do
      within('table') do
        find(:xpath, ".//tbody//tr[1]//td["+
            "contains(.//text(), '#{group.manager.entity.tag}')]").click
      end

      current_hash.should eq("documents/groups/#{group.id}")
      find_button(I18n.t('views.groups.add'))[:disabled].should eq('true')
      find_button(I18n.t('views.groups.save'))[:disabled].should eq('true')
      find_button(I18n.t('views.groups.edit'))[:disabled].should eq('false')
      find('#page-title').should have_content(
                                     I18n.t('views.groups.page_title_show'))

      within('table tbody') do
        page.should have_selector('tr', count: group.users.count)
      end

      click_button(I18n.t('views.groups.edit'))
      find('#page-title').should have_content(
                                     I18n.t('views.groups.page_title_edit'))
      find_button(I18n.t('views.groups.edit'))[:disabled].should eq('true')
      find_button(I18n.t('views.groups.add'))[:disabled].should eq('false')

      find("#group_tag")[:value].should eq(group.tag)
      find("#group_manager")[:value].should eq(group.manager.entity.tag)

      find("#group_tag")[:disabled].should eq('false')
      find("#group_manager")[:disabled].should eq('false')

      fill_in('group_tag', with: 'some different group tag')
      fill_in_autocomplete('group_manager', create(:user).entity.tag)

      click_button(I18n.t('views.groups.add'))

      within("fieldset table tbody") do
        fill_in_autocomplete("user_#{group.users.count}", create(:user).entity.tag)
      end
    end

    lambda do
      click_button(I18n.t('views.groups.save'))
      wait_until_hash_changed_to "documents/groups/#{group.id}"
    end.should change(Group, :count).by(0)

    group = Group.find(group.id)
    click_link I18n.t('views.home.groups')
    within('#container_documents') do
      within('table') do
        find(:xpath, ".//tbody//tr[1]//td["+
            "contains(.//text(), '#{group.manager.entity.tag}')]").click
      end
      current_hash.should eq("documents/groups/#{group.id}")
      find("#group_tag")[:value].should eq('some different group tag')
      find("#group_manager")[:value].should eq(group.manager.entity.tag)
      within('table tbody') do
        page.should have_selector('tr', count: group.users.count)
      end
    end
  end

  scenario "test server validation on creating group", :js => true do
    group = create(:group)
    6.times { create(:entity) }
    page_login

    page.find('#btn_create').click
    page.find("a[@href='#documents/groups/new']").click
    page.should have_xpath("//ul[@id='documents_list' and "+
                               " contains(@style, 'display: none')]")
    current_hash.should eq('documents/groups/new')

    fill_in('group_tag', with: group.tag)
    fill_in('group_manager', with: Entity.first.tag[0..2])
    page.should have_xpath("//ul[contains(@class, 'ui-autocomplete')"+
                               " and contains(@style, 'display: block')]")
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
        " and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    click_button(I18n.t('views.groups.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'activerecord.attributes.group.tag')} #{I18n.t(
            'errors.messages.taken')}")
      end
    end
  end

  scenario 'test server validation on updating group', js: true do
    create(:group)
    create(:group)
    group = Group.first
    group_last = Group.last
    page_login

    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.groups')
    current_hash.should eq('groups')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
     	                     "//li[@id='groups' and @class='sidebar-selected']")
    within('#container_documents') do
      within('table tbody') do
        find(:xpath, './/tr[1]//td[1]').click
      end
      current_hash.should eq("documents/groups/#{group.id}")

      click_button(I18n.t('views.groups.edit'))
      fill_in('group_tag', with: group_last.tag)

      click_button(I18n.t('views.groups.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'activerecord.attributes.group.tag')} #{I18n.t(
            'errors.messages.taken')}")
      end
    end
  end
end
