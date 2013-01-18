# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'places', %q{
  As an user
  I want to view places
} do

  before :each do
    create(:chart)
  end

  scenario 'view catalogs', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:catalog) }
    catalogs = Estimate::Catalog.limit(per_page).order("id ASC")
    first_catalog = catalogs[0]
    parent_catalog = catalogs[1]
    count = Estimate::Catalog.count
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_catalogs')
    current_hash.should eq('estimate/catalogs')
    page.should have_xpath("//ul[@id='slide_menu_estimate']" +
                           "/li[@id='estimate_catalogs' and @class='sidebar-selected']")

    titles = [I18n.t('views.estimates.catalogs.tag'), I18n.t('views.estimates.catalogs.activity')]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", catalogs) do |catalog|
      [catalog.tag]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    catalogs = Estimate::Catalog.limit(per_page).offset(per_page)
    check_content("#container_documents table", catalogs) do |catalog|
      [catalog.tag]
    end
    first_catalog.document = create(:document)
    first_catalog.parent = parent_catalog
    first_catalog.save!
    prev_page("div[@class='paginate']")

    page.should have_selector("div[@class='breadcrumbs'] ul li", count: 1)
    page.find(:xpath, "//table//tbody//tr[1]//td[1]").text.should eq(parent_catalog.tag)
    find("span[@data-bind='text: count']").should have_content((count-1).to_s)

    page.find(:xpath, "//table//tbody//tr[1]//td[1]").click
    page.should have_selector('table tbody tr', count: 1)
    page.should have_selector("div[@class='breadcrumbs'] ul li", count: 2)
    page.find(:xpath, "//div[@class='breadcrumbs']//ul//li[2]").text.should eq(parent_catalog.tag)
    find("span[@data-bind='text: count']").should have_content('1')
    find("span[@data-bind='text: range']").should have_content("1-1")
    within(:xpath, "//table//tbody//tr[1]//td[2]") do
      page.find("span[@class='cell-link']").text.
          should eq(I18n.t('views.estimates.catalogs.view_document'))
      page.find("span[@class='cell-link']").click
    end
    page.driver.browser.window_handles.size.should eq(2)
    page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
    page.driver.browser.close
    page.driver.browser.switch_to.window(page.driver.browser.window_handles.first)
  end

  scenario 'create/edit catalog', js: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_catalogs')
    current_hash.should eq('estimate/catalogs')
    page.should have_xpath("//ul[@id='slide_menu_estimate']" +
                               "/li[@id='estimate_catalogs' and @class='sidebar-selected']")
    click_button(I18n.t('views.estimates.catalogs.create'))

    wait_for_ajax
    wait_until_hash_changed_to "estimate/catalogs/new"
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.catalogs.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.catalogs.tag')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('catalog_tag', with: 'new catalog')
    page.should_not have_selector("#container_notification")

    find_field('catalog_parent_id')[:disabled].should eq("true")
    find_field('catalog_parent_id')[:value].should eq('')

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "estimate/catalogs/#{Estimate::Catalog.last.id}"
    end.should change(Estimate::Catalog, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.catalogs.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('catalog_tag')[:disabled].should eq("true")
    find_field('catalog_parent_id')[:disabled].should eq("true")

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "estimate/catalogs/#{Estimate::Catalog.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.catalogs.page.title.edit'))
    end

    find_field('catalog_tag')[:disabled].should be_nil
    find_field('catalog_parent_id')[:disabled].should eq("true")

    fill_in('catalog_tag', with: 'edited new catalog')

    check(I18n.t('views.estimates.catalogs.inserted_document'))
    fill_in('document_tag', with: "new document")
    fill_in('document_data', with: "new document data")

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "estimate/catalogs/#{Estimate::Catalog.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.catalogs.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('catalog_tag')[:disabled].should eq("true")
    find_field('catalog_tag')[:value].should eq('edited new catalog')
    find_field('catalog_parent_id')[:disabled].should eq("true")
    find_field('catalog_parent_id')[:value].should eq('')
    find_field('document_tag')[:disabled].should eq("true")
    find_field('document_tag')[:value].should eq('new document')
    find_field('document_data')[:disabled].should eq("true")
    find_field('document_data')[:value].should eq('new document data')
  end

  scenario 'view boms by catalog', js: true do
    c1 = build(:catalog)
    bom = create(:bo_m)
    c1.boms<<bom
    c1.save!
    c2 = create(:catalog)
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_catalogs')
    current_hash.should eq('estimate/catalogs')
    page.should have_xpath("//ul[@id='slide_menu_estimate']" +
                               "/li[@id='estimate_catalogs' and @class='sidebar-selected']")

    check_content("#container_documents table", [c1, c2]) do |catalog|
      [catalog.tag]
    end

    within(:xpath, "//table//tbody//tr[2]//td[2]") do
      page.should_not have_content(I18n.t('views.estimates.catalogs.view_boms'))
    end
    within(:xpath, "//table//tbody//tr[1]//td[2]") do
      page.find("span[@class='cell-link']").text.
          should eq(I18n.t('views.estimates.catalogs.view_boms'))
      page.find("span[@class='cell-link']").click
    end

    current_hash.should eq("estimate/bo_ms?catalog_id=#{c1.id}")
    page.should have_selector('table tbody tr', count: 1)

    check_content("#container_documents table", [bom]) do |b|
      [b.uid, b.resource.tag, b.resource.mu]
    end
  end

  scenario 'view prices by catalog', js: true do
    c1 = build(:catalog)
    pl = create(:price)
    c1.price_lists<<pl
    c1.save!
    c2 = create(:catalog)
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate.catalogs')
    current_hash.should eq('estimate/catalogs')
    page.should have_xpath("//ul[@id='slide_menu_estimate']" +
                               "/li[@id='estimate_catalogs' and @class='sidebar-selected']")

    check_content("#container_documents table", [c1, c2]) do |catalog|
      [catalog.tag]
    end

    within(:xpath, "//table//tbody//tr[2]//td[2]") do
      page.should_not have_content(I18n.t('views.estimates.catalogs.view_prices'))
    end
    within(:xpath, "//table//tbody//tr[1]//td[2]") do
      page.find("span[@class='cell-link']").text.
          should eq(I18n.t('views.estimates.catalogs.view_prices'))
      page.find("span[@class='cell-link']").click
    end

    current_hash.should eq("estimate/price_lists?catalog_id=#{c1.id}")
    page.should have_selector('table tbody tr', count: 1)

    check_content("#container_documents table", [pl]) do |p|
      [p.date.strftime('%Y-%m-%d'), p.tab, p.resource.tag, p.resource.mu]
    end
  end
end
