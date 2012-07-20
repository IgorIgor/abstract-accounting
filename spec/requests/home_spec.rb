# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'


def should_present_versions(versions)
  check_content('#container_documents table', versions) do |version|
    [version.item.class.name, version.item.storekeeper.tag,
     version.item.versions.first.created_at.strftime('%Y-%m-%d'),
     version.item.versions.last.created_at.strftime('%Y-%m-%d')]
  end
end

def table_with_paginate(scope, per_page)
  items = scope.paginate(page: 1, per_page: per_page).all(include: {item: :versions})

  should_present_versions(items)

  items_count = scope.count

  check_paginate("div[@class='paginate']", items_count, @per_page)
  next_page("div[@class='paginate']")

  items = scope.paginate(page: 2, per_page: @per_page).all(include: {item: :versions})
  should_present_versions(items)
end

feature "single page application", %q{
  As an user
  I want to work with single page
} do

  before do
    PaperTrail.enabled = true
    create(:chart)
    @waybills = []
    @allocations = []
    @per_page = Settings.root.per_page
    (0..(@per_page/2).floor).each do
      wb = build(:waybill)
      wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 10.0)
      wb.save!
      wb.apply
      @waybills << wb

      ds = build(:allocation, storekeeper: wb.storekeeper,
                              storekeeper_place: wb.storekeeper_place)
      ds.add_item(tag: 'roof', mu: 'm2', amount: 1)
      ds.save!
      @allocations << ds
    end
  end

  after { PaperTrail.enabled = false }

  scenario 'visit home page', js: true do
    page_login
    visit home_index_path
    current_path.should eq(home_index_path)
    page.should have_content("root@localhost")
    page.should have_content(I18n.t 'views.home.logout')
    page.should have_content(I18n.t 'views.home.inbox')
    page.should have_content(I18n.t 'views.home.starred')
    page.should have_content(I18n.t 'views.home.drafts')
    page.should have_content(I18n.t 'views.home.sent')
    page.should have_content(I18n.t 'views.home.trash')
    page.should have_content(I18n.t 'views.home.archive')

    current_hash.should eq("inbox")
    page.should have_selector("div[@id='container_documents'] table")
    page.find_by_id("inbox")[:class].should eq("sidebar-selected")

    page.should have_selector("div[@class='button_drop_down_list']")
    page.should have_selector("a[@id='btn_create']")
    page.should_not have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.should_not have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.find("#container_documents").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    page.should have_xpath("//div[@class='slider']")
    page.should have_xpath("//div[@id='arrow_lists' and @class='arrow-down-slide']")
    page.find('#slide_menu_lists').visible?.should eq(false)
    page.find('#btn_slide_lists').click
    page.find('#slide_menu_lists').visible?.should eq(true)
    page.should have_xpath("//div[@id='arrow_lists' and @class='arrow-up-slide']")

    page.should have_xpath("//div[@class='slider']")
    page.should have_xpath("//div[@id='arrow_conditions' and @class='arrow-down-slide']")
    page.find('#slide_menu_conditions').visible?.should eq(false)
    page.find('#btn_slide_conditions').click
    page.find('#slide_menu_conditions').visible?.should eq(true)
    page.should have_xpath("//div[@id='arrow_conditions' and @class='arrow-up-slide']")


    page.should have_xpath("//ul//li[@id='users']")
    page.should have_xpath("//ul//li[@id='groups']")
    page.should have_xpath("//ul//li[@id='resources']")
    page.should have_xpath("//ul//li[@id='entities']")
    page.should have_xpath("//ul//li[@id='places']")
    page.should have_xpath("//ul//div[@id='arrow_actions']")
    page.should have_xpath("//ul//li[@id='waybills']")
    page.should have_xpath("//ul//li[@id='allocations']")
    page.should have_xpath("//ul//li[@id='warehouses']")
    page.should have_xpath("//ul//li[@id='general_ledger']")
    page.should have_xpath("//ul//li[@id='balance_sheet']")
    page.should have_xpath("//ul//li[@id='transcripts']")
    page.should have_xpath("//div//a[@href='#settings']")

    table_with_paginate(VersionEx.lasts.by_type([ Waybill.name, Allocation.name ]),
                        @per_page)

    page.find("#show-filter").click

    within('#filter-area') do
      page.should have_content(I18n.t('views.waybills.created_at'))
      page.should have_content(I18n.t('views.waybills.document_id'))
      page.should have_content(I18n.t('views.statable.state'))
      page.should have_content(I18n.t('views.waybills.distributor'))
      page.should have_content(I18n.t('views.waybills.ident_name'))
      page.should have_content(I18n.t('views.waybills.ident_value'))
      page.should have_content(I18n.t('views.waybills.distributor_place'))
      page.should have_content(I18n.t('views.waybills.storekeeper'))
      page.should have_content(I18n.t('views.waybills.storekeeper_place'))

      select(I18n.t('views.statable.applied'), from: 'filter-w-state')
      fill_in('filter-w-created', with: '2')
      fill_in('filter-w-document', with: @waybills[0].document_id)
      fill_in('filter-w-distributor', with: @waybills[0].distributor.name)
      select(I18n.t('views.waybills.ident_name_' +
        @waybills[0].distributor.identifier_name), from: 'filter-w-ident-name')
      fill_in('filter-w-ident-value', with: @waybills[0].distributor.
                                              identifier_value)
      fill_in('filter-w-distributor-place', with: @waybills[0].
                                                    distributor_place.tag)
      fill_in('filter-w-storekeeper', with: @waybills[0].storekeeper.tag)
      fill_in('filter-w-storekeeper-place', with: @waybills[0].
                                                    storekeeper_place.tag)

      click_button(I18n.t('views.home.search'))
    end

    pending "disabled while fix filter with new allocation and waybill fields"

    should_present_versions([@waybills[0]])

    page.find("#show-filter").click

    within('#filter-area') do
      page.find(:xpath, "//div[@class='tabs']//ul//li//a[contains(.//text(),
            '#{I18n.t('views.home.allocation')}')]").click

      page.should have_content(I18n.t('views.allocations.created_at'))
      page.should have_content(I18n.t('views.statable.state'))
      page.should have_content(I18n.t('views.allocations.storekeeper'))
      page.should have_content(I18n.t('views.allocations.storekeeper_place'))
      page.should have_content(I18n.t('views.allocations.foreman'))
      page.should have_content(I18n.t('views.allocations.foreman_place'))

      fill_in('filter-a-created', with: '2')
      select(I18n.t('views.statable.inwork'), from: 'filter-a-state')

      fill_in('filter-a-storekeeper', with: @allocations[0].storekeeper.tag)
      fill_in('filter-a-storekeeper-place', with: @allocations[0].
                                                    storekeeper_place.tag)
      fill_in('filter-a-foreman', with: @allocations[0].foreman.tag)
      fill_in('filter-a-foreman-place', with: @allocations[0].
                                                foreman_place.tag)

      click_button(I18n.t('views.home.search'))
    end

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 2)
      page.should have_content(@allocations[0].class.name)
      page.should have_content(@allocations[0].storekeeper.tag)
      page.should have_content(@allocations[0].versions.first.created_at.
                                 strftime('%Y-%m-%d'))
      page.should have_content(@allocations[0].versions.last.created_at.
                                 strftime('%Y-%m-%d'))
    end

    click_link I18n.t('views.home.logout')

    user = create(:user)
    VersionEx.where{item_type.in([Waybill.name, Allocation.name])}.delete_all
    page_login

    check_content("#container_documents table", [user]) do |item|
      [item.class.name, item.entity.tag,
       item.versions.first.created_at.strftime('%Y-%m-%d'),
       item.versions.last.created_at.strftime('%Y-%m-%d')]
    end
  end

  scenario "non root user should see only information accessible by him", js: true do
    password = "password"
    user = create(:user, :password => password)

    page_login(user.email, password)
    page.should have_content(user.entity.tag)
    page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")
    page.should_not have_xpath("//div[@id='container_documents']//table//tbody//tr")
    page.should_not have_xpath("//ul[@id='documents_list']//li")

    page.should have_xpath("//div[@class='slider']")
    page.should have_xpath("//div[@id='arrow_lists' and @class='arrow-down-slide']")
    page.should_not have_xpath("//ul//li[@id='users']")
    page.should_not have_xpath("//ul//li[@id='groups']")
    page.should_not have_xpath("//ul//li[@id='assets']")
    page.should_not have_xpath("//ul//li[@id='entities']")
    page.should_not have_xpath("//ul//li[@id='places']")
    page.should_not have_xpath("//ul//div[@id='arrow_actions']")
    page.should have_xpath("//ul//li[@id='waybills']")
    page.should have_xpath("//ul//li[@id='allocations']")
    page.should have_xpath("//ul//li[@id='warehouses']")
    page.should_not have_xpath("//ul//li[@id='general_ledger']")
    page.should_not have_xpath("//ul//li[@id='balance_sheet']")
    page.should_not have_xpath("//ul//li[@id='transcripts']")
    page.should_not have_xpath("//div//a[@href='#settings']")

    click_link I18n.t('views.home.logout')

    credential = create(:credential, user: user, document_type: Waybill.name)

    page_login(user.email, password)
    within(:xpath, "//ul[@id='documents_list']") do
      page.should have_selector("li", count: user.credentials(:force_update).count)
      user.credentials(:force_update).each do |cred|
        page.should have_content(I18n.t("views.home.#{cred.document_type.underscore}"))
      end
    end
    page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")
    within('#container_documents table tbody') do
      page.should_not have_selector("tr")
    end
    click_link I18n.t('views.home.logout')

    5.times do |i|
      wb = build(:waybill, storekeeper: user.entity,
                           storekeeper_place: i < 3 ? credential.place : create(:place))
      wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 10.0)
      wb.save!
      wb.apply

      ds = build(:allocation, storekeeper: wb.storekeeper,
                              storekeeper_place: wb.storekeeper_place)
      ds.add_item(tag: 'roof', mu: 'm2', amount: 1)
      ds.save!
    end

    versions = VersionEx.lasts.
      by_type(user.credentials(:force_update).collect { |c| c.document_type }).
      by_user(user).paginate(page: 1, per_page: @per_page).all
    page_login(user.email, password)
    page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")

    should_present_versions(versions)

    within('#container_documents table tbody') do
      page.should_not have_content(Allocation.name)
    end
    click_link I18n.t('views.home.logout')

    credential = create(:credential, user: user, document_type: Allocation.name)

    page_login(user.email, password)
    within(:xpath, "//ul[@id='documents_list']") do
      page.should have_selector("li", count: user.credentials(:force_update).count)
      user.credentials(:force_update).each do |cred|
        page.should have_content(I18n.t("views.home.#{cred.document_type.underscore}"))
      end
    end
    page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")
    within('#container_documents table tbody') do
      page.should_not have_content(Allocation.name)
    end
    click_link I18n.t('views.home.logout')

    credential.update_attributes(place:
      user.credentials(:force_update).find_by_document_type(Waybill.name).place)

    page_login(user.email, password)
    within(:xpath, "//ul[@id='documents_list']") do
      page.should have_selector("li", count: user.credentials(:force_update).count)
      user.credentials(:force_update).each do |cred|
        page.should have_content(I18n.t("views.home.#{cred.document_type.underscore}"))
      end
    end
    page.should have_xpath("//li[@id='inbox' and @class='sidebar-selected']")
    versions = VersionEx.lasts.
      by_type(user.credentials(:force_update).collect { |c| c.document_type }).
      by_user(user).paginate(page: 1, per_page: @per_page).all

    should_present_versions(versions)

    click_link I18n.t('views.home.logout')
  end

  scenario 'visit archive page', js: true do
    page_login
    visit home_index_path
    current_path.should eq(home_index_path)
    page.find("a[@href='#archive']").click

    current_hash.should eq("archive")
    page.should have_selector("div[@id='container_documents'] table")
    page.find_by_id("archive")[:class].should eq("sidebar-selected")

    table_with_paginate(VersionEx.lasts.by_type([ Waybill.name, Allocation.name ]),
                        @per_page)

    page.find("#show-filter").click

    within('#filter-area') do
      page.should have_content(I18n.t('views.waybills.created_at'))
      page.should have_content(I18n.t('views.waybills.document_id'))
      page.should have_content(I18n.t('views.statable.state'))
      page.should have_content(I18n.t('views.waybills.distributor'))
      page.should have_content(I18n.t('views.waybills.ident_name'))
      page.should have_content(I18n.t('views.waybills.ident_value'))
      page.should have_content(I18n.t('views.waybills.distributor_place'))
      page.should have_content(I18n.t('views.waybills.storekeeper'))
      page.should have_content(I18n.t('views.waybills.storekeeper_place'))

      select(I18n.t('views.statable.applied'), from: 'filter-w-state')
      fill_in('filter-w-created', with: '2')
      fill_in('filter-w-document', with: @waybills[0].document_id)
      fill_in('filter-w-distributor', with: @waybills[0].distributor.name)
      select(I18n.t('views.waybills.ident_name_' +
        @waybills[0].distributor.identifier_name), from: 'filter-w-ident-name')
      fill_in('filter-w-ident-value', with: @waybills[0].distributor.
                                              identifier_value)
      fill_in('filter-w-distributor-place', with: @waybills[0].
                                                    distributor_place.tag)
      fill_in('filter-w-storekeeper', with: @waybills[0].storekeeper.tag)
      fill_in('filter-w-storekeeper-place', with: @waybills[0].
                                                    storekeeper_place.tag)

      click_button(I18n.t('views.home.search'))
    end

    click_link I18n.t('views.home.logout')

    user = create(:user)
    VersionEx.where{item_type.in([Waybill.name, Allocation.name])}.delete_all
    page_login

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      page.should have_content(user.class.name)
      page.should have_content(user.entity.tag)
      page.should have_content(user.versions.first.created_at.
                                 strftime('%Y-%m-%d'))
      page.should have_content(user.versions.last.created_at.
                                 strftime('%Y-%m-%d'))
    end
  end
end
