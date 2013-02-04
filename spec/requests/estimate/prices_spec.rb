# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'price_list', %q{
  As an user
  I want to view price_list
} do

  before :each do
    create :chart
    asset = create :asset
    @bom = Estimate::BoM.new(uid: "123", resource_id: asset.id)
    @bom.element_builders(150, 250)
    @bom.element_machinist(150)
    mach = create(:asset, tag: 'auto', mu: I18n.t('views.estimates.elements.mu.machine'))
    res = create(:asset, tag: 'hummer', mu: 'sht')
    @bom.element_items({code: '123', rate: 150, id: mach.id },Estimate::BoM::MACHINERY)
    @bom.element_items({code: '234', rate: 250, id: res.id },Estimate::BoM::RESOURCES)
    @bom.save.should be_true

    asset = create :asset
    bom = Estimate::BoM.new(uid: "654", resource_id: asset.id)
    bom.element_builders(970, 570)
    bom.element_machinist(1770)
    mach = create(:asset, tag: 'meha', mu: I18n.t('views.estimates.elements.mu.machine'))
    res = create(:asset, tag: 'roof', mu: 'kg')
    bom.element_items({code: '9823', rate: 1850, id: mach.id },Estimate::BoM::MACHINERY)
    bom.element_items({code: '2034', rate: 2950, id: res.id },Estimate::BoM::RESOURCES)
    bom.save.should be_true

    asset = create :asset
    bom = Estimate::BoM.new(uid: "789", resource_id: asset.id)
    bom.element_builders(970, 570)
    bom.save.should be_true
  end

  scenario 'price - list', js: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.price_list')
    current_hash.should eq('estimates/price_lists/new')
    page.should have_content(I18n.t('views.estimates.date'))
    page.should have_content(I18n.t('views.estimates.uid'))
    page.should have_content(I18n.t('views.resources.tag'))
    page.should have_content(I18n.t('views.resources.mu'))
    page.should have_content(I18n.t('views.estimates.catalog'))
    titles = [I18n.t('views.estimates.code'), I18n.t('views.resources.tag'),
              I18n.t('views.resources.mu'), I18n.t('views.estimates.rate')]
    check_header("#container_documents table", titles)

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.price_list.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    find_field('date')[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    find_field('price_list_catalog')[:disabled].should eq(nil)

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.uid')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.date')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.catalog')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.datepicker("date").prev_month.day(1)
    fill_in('uid', :with => '1')
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    2.times{ create(:catalog) }
    catalogs = Estimate::Catalog.order("id ASC").all
    catalog = catalogs[0]
    find('#price_list_catalog').click
    page.should have_selector('#catalogs_selector')
    within('#catalogs_selector') do
      within('table tbody') do
        within(:xpath, './/tr[1]//td[2]') do
          find("span[@class='cell-link']").click
        end
      end
    end
    page.should have_no_selector('#catalogs_selector')

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('3')
    page.should have_content(I18n.t('views.estimates.elements.machinery'))
    page.should have_content(I18n.t('views.estimates.elements.mu.machine'))

    page.should have_content('4')
    page.should have_content(I18n.t('views.estimates.elements.resources'))

    find_field('builders_rate')[:disabled].should eq(nil)
    find_field('machinist_rate')[:disabled].should eq(nil)
    find_field('machinery#0')[:disabled].should eq(nil)
    find_field('resources#0')[:disabled].should eq(nil)

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')}. #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinist')}. #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('builders_rate', :with => 'a')
    fill_in('machinist_rate', :with => 'b')
    fill_in('machinery#0', :with => 'c')
    fill_in('resources#0', :with => 'd')

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')}. #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinist')}. #{I18n.t(
            'views.estimates.price')} : #{I18n.t('errors.messages.number')}")
      end
    end

    fill_in('builders_rate', :with => '1.5')
    fill_in('machinist_rate', :with => '2.5')
    fill_in('machinery#0', :with => '3.5')
    fill_in('resources#0', :with => '4.5')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    price_list = Estimate::PriceList.last
    wait_until_hash_changed_to "estimates/price_lists/#{price_list.id}"
    price_list.items.count.should eq(4)

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.price_list.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('date')[:disabled].should eq("true")
    find_field('uid')[:disabled].should eq("true")
    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    find_field('price_list_catalog')[:disabled].should eq("true")
    find_field('builders_rate')[:disabled].should eq("true")
    find_field('machinist_rate')[:disabled].should eq("true")
    find_field('machinery#0')[:disabled].should eq("true")
    find_field('resources#0')[:disabled].should eq("true")

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('3')
    page.should have_content(I18n.t('views.estimates.elements.machinery'))
    page.should have_content(I18n.t('views.estimates.elements.mu.machine'))

    page.should have_content('4')
    page.should have_content(I18n.t('views.estimates.elements.resources'))

    find_field('date')[:value].should eq(price_list.date.strftime('%m/%Y'))
    find_field('uid')[:value].should eq(price_list.bo_m.uid)
    find_field('asset_tag')[:value].should eq(price_list.bo_m.resource.tag)
    find_field('asset_mu')[:value].should eq(price_list.bo_m.resource.mu)
    find_field('price_list_catalog')[:value].should eq(catalog.tag)
    find_field('builders_rate')[:value].should eq(price_list.
                                  item_by_element_type(Estimate::BoM::BUILDERS)[0].rate.to_s)
    find_field('machinist_rate')[:value].should eq(price_list.
                                  item_by_element_type(Estimate::BoM::MACHINIST)[0].rate.to_s)
    find_field('machinery#0')[:value].should eq(price_list.
                                  item_by_element_type(Estimate::BoM::MACHINERY)[0].rate.to_s)
    find_field('resources#0')[:value].should eq(price_list.
                                  item_by_element_type(Estimate::BoM::RESOURCES)[0].rate.to_s)
    find_field('builders_rate')[:value].should eq('1.5')
    find_field('machinist_rate')[:value].should eq('2.5')
    find_field('machinery#0')[:value].should eq('3.5')
    find_field('resources#0')[:value].should eq('4.5')

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.price_list.page.title.edit'))
    end

    find_field('date')[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    find_field('price_list_catalog')[:disabled].should eq(nil)
    find_field('builders_rate')[:disabled].should eq(nil)
    find_field('machinist_rate')[:disabled].should eq(nil)
    find_field('machinery#0')[:disabled].should eq(nil)
    find_field('resources#0')[:disabled].should eq(nil)


    page.datepicker("date").prev_month.prev_month.day(1)
    fill_in('uid', :with => '6')
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    fill_in('builders_rate', :with => '5.5')
    fill_in('machinist_rate', :with => '5.5')
    fill_in('machinery#0', :with => '5.5')
    fill_in('resources#0', :with => '5.5')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    price_list = Estimate::PriceList.last
    wait_until_hash_changed_to "estimates/price_lists/#{price_list.id}"
    price_list.items.count.should eq(4)

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.price_list.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('date')[:disabled].should eq("true")
    find_field('uid')[:disabled].should eq("true")
    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    find_field('builders_rate')[:disabled].should eq("true")
    find_field('machinist_rate')[:disabled].should eq("true")
    find_field('machinery#0')[:disabled].should eq("true")
    find_field('resources#0')[:disabled].should eq("true")

    find_field('date')[:value].should eq(price_list.date.strftime('%m/%Y'))
    find_field('uid')[:value].should eq(price_list.bo_m.uid)
    find_field('asset_tag')[:value].should eq(price_list.bo_m.resource.tag)
    find_field('asset_mu')[:value].should eq(price_list.bo_m.resource.mu)
    find_field('builders_rate')[:value].should eq(price_list.
                item_by_element_type(Estimate::BoM::BUILDERS)[0].rate.to_s)
    find_field('machinist_rate')[:value].should eq(price_list.
                item_by_element_type(Estimate::BoM::MACHINIST)[0].rate.to_s)
    find_field('machinery#0')[:value].should eq(price_list.
                item_by_element_type(Estimate::BoM::MACHINERY)[0].rate.to_s)
    find_field('resources#0')[:value].should eq(price_list.
                item_by_element_type(Estimate::BoM::RESOURCES)[0].rate.to_s)
    find_field('builders_rate')[:value].should eq('5.5')
    find_field('machinist_rate')[:value].should eq('5.5')
    find_field('machinery#0')[:value].should eq('5.5')
    find_field('resources#0')[:value].should eq('5.5')

    visit '#inbox'
    click_link I18n.t('views.home.price_list')
    current_hash.should eq('estimates/price_lists/new')
    page.datepicker("date").prev_month.prev_month.day(1)
    fill_in('uid', :with => '6')
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    fill_in('builders_rate', :with => '1')
    fill_in('machinist_rate', :with => '1')
    fill_in('machinery#0', :with => '1')
    fill_in('resources#0', :with => '1')

    click_button(I18n.t('views.users.save'))
    find("#container_notification").visible?.should be_true

    visit '#inbox'
    click_link I18n.t('views.home.price_list')
    page.datepicker("date").prev_month.prev_month.day(1)
    fill_in('uid', :with => '7')
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should_not have_no_content('2')
    page.should_not have_no_content(I18n.t('views.estimates.elements.machinist'))
    page.should_not have_no_content(I18n.t('views.estimates.elements.mu.people'))

    page.should_not have_no_content('3')
    page.should_not have_no_content(I18n.t('views.estimates.elements.machinery'))
    page.should have_no_content(I18n.t('views.estimates.elements.mu.machine'))

    page.should_not have_no_content('4')
    page.should_not have_no_content(I18n.t('views.estimates.elements.resources'))
  end

  scenario 'view and sort price lists', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:price_list)}
    count = Estimate::PriceList.all.count
    pls = Estimate::PriceList.limit(per_page)

    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_price_lists')
    current_hash.should eq('estimate/price_lists')

    titles = [I18n.t('views.estimates.uid'), I18n.t('views.estimates.date'),
              I18n.t('views.resources.tag'), I18n.t('views.resources.mu'),
              I18n.t('views.estimates.catalogs.tag')]
    wait_for_ajax

    check_header("#container_documents table", titles)
    check_content("#container_documents table", pls) do |pl|
      [pl.date.strftime('%m/%Y'), pl.bo_m.uid, pl.bo_m.resource.tag, pl.bo_m.resource.mu, pl.catalog.tag]
    end
    check_paginate("div[@class='paginate']", count, per_page)

    test_order = lambda do |field, type|
      pls = Estimate::PriceList.limit(per_page).send("sort_by_#{field}","#{type}")
      within('#container_documents table') do
        within('thead tr') do
          page.find("##{field}").click
          if type == 'asc'
            page.should have_xpath("//th[@id='#{field}']" +
                                       "/span[@class='ui-icon ui-icon-triangle-1-s']")
          elsif type == 'desc'
            page.should have_xpath("//th[@id='#{field}']" +
                                       "/span[@class='ui-icon ui-icon-triangle-1-n']")
          end
        end
      end
      check_content("#container_documents table", pls) do |pl|
        [pl.date.strftime('%m/%Y'), pl.bo_m.uid, pl.bo_m.resource.tag, pl.bo_m.resource.mu, pl.catalog.tag]
      end
    end

    test_order.call('date','asc')
    test_order.call('date','desc')
    test_order.call('uid','asc')
    test_order.call('uid','desc')
    test_order.call('tag','asc')
    test_order.call('tag','desc')
    test_order.call('mu','asc')
    test_order.call('mu','desc')
    test_order.call('catalog_tag','asc')
    test_order.call('catalog_tag','desc')
  end

  scenario 'show price', js: true, focus: true do
    10.times { create(:price_list) }
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate.price.data')
    wait_for_ajax
    find(:xpath, "//tr[1]/td[1]").click
    wait_for_ajax
    pl = Estimate::PriceList.first
    current_hash.should eq("estimate/prices/#{pl.id}")
  end
end
