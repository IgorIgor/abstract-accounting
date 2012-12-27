# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'foreman/resources', %q{
  As an user
  I want to view foreman/resources
} do

  before :each do
    create :chart
    PaperTrail.enabled = true
    @per_page = Settings.root.per_page

    @place = create(:place, tag: 'place')
    @user = create(:user)
    create(:credential, user: @user, place: @place, document_type: Allocation.name)
    create(:credential, user: @user, place: @place, document_type: Waybill.name)
    PaperTrail.whodunnit = @user
    @foreman = create(:user)
    create(:credential, user: @foreman, place: @place, document_type: WarehouseForemanReport.name)
    wb = build(:waybill,  storekeeper_place: @place)
    (0..@per_page).each do |i|
      wb.add_item(tag: "nails#{i}", amount: 500 + i, price: 666, mu: "pcs#{i}")
    end
    wb.save!
    wb.apply
    al = Allocation.new(created: Date.today,
                        foreman_id: @foreman.entity_id,
                        foreman_type: Entity.name,
                        foreman_place_id: @place.id,
                        storekeeper_id: wb.storekeeper.id,
                        storekeeper_type: wb.storekeeper.class.name,
                        storekeeper_place_id: wb.storekeeper_place.id)
    (0..@per_page).each do |i|
      al.add_item(tag: "nails#{i}", mu: "pcs#{i}", amount: 500 + i)
    end
    al.save
    al.apply
  end

  after :each do
    PaperTrail.whodunnit = nil
    PaperTrail.enabled = false
  end

  scenario 'view resources', js: true do
    page_login(@foreman.email, @foreman.crypted_password)
    find("#btn_slide_lists").click
    click_link I18n.t('views.home.foreman_report')
    titles = [I18n.t('views.warehouses.foremen.report.resource.name'),
              I18n.t('views.warehouses.foremen.report.resource.mu'),
              I18n.t('views.warehouses.foremen.report.amount'),
              I18n.t('views.warehouses.foremen.report.price'),
              I18n.t('views.warehouses.foremen.report.sum')]
    check_header("#container_documents table", titles)

    page.should have_datepicker("foremen_filter_from")
    page.should have_datepicker("foremen_filter_to")
    page.should have_selector("#print")

    check_paginate("div[@class='paginate']", @per_page + 1, @per_page)

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 1, per_page: @per_page }
    resources = WarehouseForemanReport.all(args)

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: @per_page)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    next_page("div[@class='paginate']")

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 2, per_page: @per_page }
    resources = WarehouseForemanReport.all(args)
    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    page.datepicker("foremen_filter_to").prev_month.day(10)

    within('#container_documents table') do
      page.should_not have_selector('tbody tr')
    end

    page.should_not have_selector("#print")

    visit "/foreman/resources/data.html"
    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current }
    resources = WarehouseForemanReport.all(args)
    count = WarehouseForemanReport.count(args)
    within('#pdf-wrapper table') do
      page.should have_selector('thead tr')
      page.should have_content(I18n.t('views.warehouses.foremen.report.index'))
      page.should have_content(I18n.t('views.warehouses.foremen.report.resource.name'))
      page.should have_content(I18n.t('views.warehouses.foremen.report.resource.mu'))
      page.should have_content(I18n.t('views.warehouses.foremen.report.amount'))
      page.should have_content(I18n.t('views.warehouses.foremen.report.price'))
      page.should have_content(I18n.t('views.warehouses.foremen.report.sum'))
      page.should have_selector('tbody tr', count: count)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end
  end

  scenario 'sort foreman resources', js: true do
    page_login(@foreman.email, @foreman.crypted_password)
    find("#btn_slide_lists").click
    click_link I18n.t('views.home.foreman_report')
    test_order = lambda do |field, type|
      wfr = WarehouseForemanReport.all(warehouse_id: @place.id,
                                         sort: { field: field, type: type},
                                         page: 1, per_page: @per_page,
                                         foreman_id: @foreman.id)
      wait_for_ajax
      within('#container_documents table') do
        wait_for_ajax
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
      check_content("#container_documents table", wfr) do |item|
        [item.resource.tag, item.resource.mu, item.amount.to_i, item.price.to_i,
         (item.amount.to_i * item.price.to_i).to_i]
      end
    end

    test_order.call('tag','asc')
    test_order.call('tag','desc')

    test_order.call('mu','asc')
    test_order.call('mu','desc')

    test_order.call('amount','asc')
    test_order.call('amount','desc')

    visit "/foreman/resources/data.html?order%5Btype%5D=desc&order%5Bfield%5D=amount"
    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              sort: { field: 'amount', type: 'desc'} }
    resources = WarehouseForemanReport.all(args)
    count = WarehouseForemanReport.count(args)
    within('#pdf-wrapper table') do
      page.should have_selector('tbody tr', count: count)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end
  end

  scenario 'search foreman resources', js: true do
    page_login(@foreman.email, @foreman.crypted_password)
    find("#btn_slide_lists").click
    click_link I18n.t('views.home.foreman_report')
    wait_for_ajax
    find("#show-filter").click
    titles = [I18n.t('views.warehouses.foremen.report.resource.name'),
              I18n.t('views.warehouses.foremen.report.resource.mu'),
              I18n.t('views.warehouses.foremen.report.amount')]
    within('#filter-area') do
      titles.each do |title|
        page.should have_content(title)
      end
      fill_in('filter-tag', with: 'na')
      fill_in('filter-mu', with: 's')
      fill_in('filter-amount', with: 501)

      click_button(I18n.t('views.home.search'))
    end

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 1, per_page: @per_page,
              search: { tag: 'na', mu: 's', amount: 501 }}
    resources = WarehouseForemanReport.all(args)
    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    page.find("#show-filter").click

    within('#filter-area') do
      find('#filter-tag')[:value].should eq('na')
      find('#filter-mu')[:value].should eq('s')
      find('#filter-amount')[:value].should eq('501')

      find("#clear_filter").click

      find('#filter-tag')[:value].should eq('')
      find('#filter-mu')[:value].should eq('')
      find('#filter-amount')[:value].should eq('')

      click_button(I18n.t('views.home.search'))
    end

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 1, per_page: @per_page}
    resources = WarehouseForemanReport.all(args)
    within('#container_documents table') do
      wait_for_ajax
      page.should have_selector('tbody tr', count: @per_page)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    page.find("#show-filter").click
    within('#filter-area') do
      fill_in('filter-tag', with: 'nails')
      fill_in('filter-mu', with: 'pcs')

      click_button(I18n.t('views.home.search'))
    end

    check_paginate("div[@class='paginate']", @per_page + 1, @per_page)

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 1, per_page: @per_page }
    resources = WarehouseForemanReport.all(args)

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: @per_page)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    next_page("div[@class='paginate']")

    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 2, per_page: @per_page }
    resources = WarehouseForemanReport.all(args)
    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    tag_for_search = 'nails5'

    page.find("#show-filter").click
    within('#filter-area') do
      fill_in('filter-tag', with: tag_for_search)

      click_button(I18n.t('views.home.search'))
    end

    visit "/foreman/resources/data.html?search%5Btag%5D=#{tag_for_search}"
    args = {  warehouse_id: @place.id,
              foreman_id: @foreman.entity_id,
              search: {tag: tag_for_search},
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current }
    resources = WarehouseForemanReport.all(args)
    count = WarehouseForemanReport.count(args)
    within('#pdf-wrapper table') do
      page.should have_selector('tbody tr', count: @count)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end
  end
end
