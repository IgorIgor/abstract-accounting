# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

def should_have_header
  within('thead tr') do
    page.should have_content(I18n.t('views.warehouses.place'))
    page.should have_content(I18n.t('views.warehouses.tag'))
    page.should have_content(I18n.t('views.warehouses.real_amount'))
    page.should have_content(I18n.t('views.warehouses.expectation_amount'))
    page.should have_content(I18n.t('views.warehouses.mu'))
  end
end

def should_present_warehouse(warehouse)
  page.should have_content(warehouse.place)
  page.should have_content(warehouse.tag)
  page.should have_content(warehouse.real_amount.to_i)
  page.should have_content(warehouse.exp_amount.to_i)
  page.should have_content(warehouse.mu)
end

feature 'warehouses', %q{
  As an user
  I want to view warehouses
} do

  before :each do
    create(:chart)
  end

  scenario 'view warehouses', js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    (0..per_page).each do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    page_login
    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    titles = [I18n.t('views.warehouses.place'), I18n.t('views.warehouses.tag'),
              I18n.t('views.warehouses.real_amount'),
              I18n.t('views.warehouses.expectation_amount'),
              I18n.t('views.warehouses.mu')]

    check_header("#container_documents table", titles)

    page.find("#show-filter").click

    within('#filter-area') do
      titles.each do |title|
        page.should have_content(title)
      end

      fill_in('filter-place', with: wb.storekeeper_place.tag)
      fill_in('filter-tag', with: 'resource#0')
      fill_in('filter-real-amount', with: 100)
      fill_in('filter-exp-amount', with: 100)
      fill_in('filter-mu', with: 'mu0')

      click_button(I18n.t('views.home.search'))
    end

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      page.should have_content(wb.storekeeper_place.tag)
      page.should have_content("resource#0")
      page.should have_content("mu0")
      page.should have_content(100)
    end

    check_paginate("div[@class='paginate']", 1, 1)

    page.find("#show-filter").click

    within('#filter-area') do
      fill_in('filter-place', with: '')
      fill_in('filter-tag', with: '')
      fill_in('filter-real-amount', with: '')
      fill_in('filter-exp-amount', with: '')
      fill_in('filter-mu', with: '')

      click_button(I18n.t('views.home.search'))
    end

    check_paginate("div[@class='paginate']", Warehouse.count, per_page)

    warehouses = Warehouse.all(per_page: per_page, page: 1)
    check_content("#container_documents table", warehouses) do |warehouse|
      [warehouse.place, warehouse.tag, warehouse.real_amount.to_i,
       warehouse.exp_amount.to_i, warehouse.mu]
    end

    next_page("div[@class='paginate']")
    warehouses = Warehouse.all(per_page: per_page, page: 2)
    check_content("#container_documents table", warehouses) do |warehouse|
      [warehouse.place, warehouse.tag, warehouse.real_amount.to_i,
       warehouse.exp_amount.to_i, warehouse.mu]
    end
  end

  scenario "user without root credentials should see only his data", js: true do
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Waybill.name)
    create(:credential, user: user, place: credential.place, document_type: Allocation.name)

    wb = build(:waybill)
    5.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    page_login(user.email, password)

    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    titles = [I18n.t('views.warehouses.place'), I18n.t('views.warehouses.tag'),
              I18n.t('views.warehouses.real_amount'),
              I18n.t('views.warehouses.expectation_amount'),
              I18n.t('views.warehouses.mu')]

    check_header("#container_documents table", titles)

    within('#container_documents table') do
      page.should_not have_selector("tbody tr")
    end
    click_link I18n.t('views.home.logout')

    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
    5.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    page_login(user.email, password)

    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    resources = Warehouse.all(where: { warehouse_id: { equal: credential.place_id } })

    check_header("#container_documents table", titles)
    check_content("#container_documents table", resources) do |resource|
      [resource.place, resource.tag, resource.real_amount.to_i,
       resource.exp_amount.to_i, resource.mu]
    end

    click_link I18n.t('views.home.logout')
  end

  scenario 'grouping warehouses', js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    wb2 = build(:waybill)

    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 100+i, amount: 10+i)
    end

    wb.save!
    wb.apply

    (0..per_page).each { |i|
      wb2.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 500+i, amount: 50+i)
    }
    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: per_page, visible: true)
    end

    select(I18n.t('views.warehouses.group_place'), from: 'warehouse_group')

    resources = Warehouse.
        all(where: { place_id: { equal_attr: wb.storekeeper_place.id } })
    resources.length.should eq(3)

    within('#container_documents table tbody') do
      all("tr", visible: true)
      page.should have_selector('tr', count: 2, visible: true)
      page.should have_content(wb.storekeeper_place.tag)
      page.should have_content(wb2.storekeeper_place.tag)
      page.should have_selector(:xpath,
                      ".//tr//td[@class='distribution-tree-actions-by-wb']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']", count: 2)
      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click

      page.should have_xpath(".//tr[@id='group_#{wb.
          storekeeper_place.id}']//td[@class='td-inner-table']")


      check_paginate("#group_#{wb.storekeeper_place.id} div[@class='paginate']",
                     resources.length, per_page)

      check_content("#group_#{wb.storekeeper_place.id} table[@class='inner-table']",
                    resources) do |resource|
        [wb.storekeeper_place.tag, resource.tag, resource.real_amount.to_i,
         resource.exp_amount.to_i, resource.mu]
      end

      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      page.should_not have_selector("#group_#{wb2.storekeeper_place.id}")

      resources = Warehouse.
          all(per_page: per_page, page: 1,
              where: { place_id: { equal_attr: wb2.storekeeper_place.id } })
      #resources.length.should eq(per_page + 1)
      count = Warehouse.
          all(where: { place_id: { equal_attr: wb2.storekeeper_place.id } }).count

      find(:xpath,
           ".//tr[3]//td[@class='distribution-tree-actions-by-wb']").click

      check_content("#group_#{wb2.storekeeper_place.id} table[@class='inner-table']",
                    resources) do |resource|
        [wb2.storekeeper_place.tag, resource.tag, resource.real_amount.to_i,
         resource.exp_amount.to_i, resource.mu]
      end

      check_paginate("#group_#{wb2.storekeeper_place.id} div[@class='paginate']",
                     count, per_page)
      next_page("#group_#{wb2.storekeeper_place.id} div[@class='paginate']")

      resources = Warehouse.
          all(per_page: per_page, page: 2,
              where: { place_id: { equal_attr: wb2.storekeeper_place.id } })

      check_content("#group_#{wb2.storekeeper_place.id} table[@class='inner-table']",
                    resources) do |resource|
        [wb2.storekeeper_place.tag, resource.tag, resource.real_amount.to_i,
         resource.exp_amount.to_i, resource.mu]
      end

      prev_page("#group_#{wb2.storekeeper_place.id} div[@class='paginate']")

      find(:xpath,
           ".//tr[3]//td[@class='distribution-tree-actions-by-wb']").click
      page.should_not have_selector("#group_#{wb2.storekeeper_place.id}")
    end

    select(I18n.t('views.warehouses.group_tag'), from: 'warehouse_group')

    check_paginate("div[@class='paginate']", per_page + 1, per_page)
    next_page("div[@class='paginate']")

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1, visible: true)
      page.should have_content(Asset.last.tag)
    end

    prev_page("div[@class='paginate']")

    items = wb2.items
    within('#container_documents table tbody') do
      per_page.times do |i|
        page.should have_content(items[i].resource.tag)
      end
    end

    resource = Asset.find_by_tag_and_mu('resource#0', 'mu#0')
    resources = Warehouse.
        all(where: { asset_id: { equal_attr: resource.id } })
    resources.length.should eq(2)

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: per_page, visible: true)
      page.should have_selector(:xpath,
                      ".//tr//td[@class='distribution-tree-actions-by-wb']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']",
                      count: per_page)

      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click

      page.should have_selector("#group_#{resource.id} td[@class='td-inner-table']")

      check_paginate("#group_#{resource.id} div[@class='paginate']",
                     resources.length, per_page)

      within("#group_#{resource.id}") do
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: resources.length)
          page.should have_content(wb.storekeeper_place.tag)
          page.should have_content(wb2.storekeeper_place.tag)
          page.should have_content(resource.tag)
          resources.each do |r|
            page.should have_content(r.real_amount.to_i)
            page.should have_content(r.exp_amount.to_i)
            page.should have_content(r.mu)
          end
        end
      end
      find(:xpath,
           ".//tr[1]//td[@class='distribution-tree-actions-by-wb']").click
      page.should_not have_selector("#group_#{resource.id}")
    end
  end

  scenario "none root user should not see grouping filter", js: true do
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Waybill.name)
    credential = create(:credential, user: user, document_type: Allocation.name)
    page_login(user.email, password)

    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    page.should have_no_xpath("//select[@id='warehouse_group']")
  end

  scenario 'sort warehouses', js: true do
    moscow = create(:place, tag: 'Moscow')
    kiev = create(:place, tag: 'Kiev')
    amsterdam = create(:place, tag: 'Amsterdam')

    wb1 = build(:waybill, storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 10.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, storekeeper_place: kiev)
    wb2.add_item(tag: 'foo', mu: 'hex', amount: 200, price: 40.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, storekeeper_place: amsterdam)
    wb3.add_item(tag: 'bar', mu: 'ant', amount: 300, price: 20.0)
    wb3.save!
    wb3.apply

    page_login
    page.find('#btn_slide_conditions').click
    page.find('#warehouses a').click
    current_hash.should eq('warehouses')
    page.should have_xpath("//ul[@id='slide_menu_conditions']" +
                           "/li[@id='warehouses' and @class='sidebar-selected']")

    within('#container_documents table') do

      test_order = lambda do |field, type|
        warehouses = Warehouse.all(order_by: { field: field, type: type })
        count = Warehouse.count
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
        within('tbody') do
          page.should have_selector('tr', count: count)
          count.times do |i|
            within(:xpath, ".//tr[#{i + 1}]") do
              should_present_warehouse(warehouses[i])
            end
          end
        end
      end

      test_order.call('place','asc')
      test_order.call('place','desc')

      test_order.call('tag','asc')
      test_order.call('tag','desc')

      test_order.call('mu','asc')
      test_order.call('mu','desc')

      test_order.call('real_amount','asc')
      test_order.call('real_amount','desc')

      test_order.call('exp_amount','asc')
      test_order.call('exp_amount','desc')
    end
  end
end
