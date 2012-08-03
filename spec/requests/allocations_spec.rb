# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

def show_allocation(allocation)

  current_hash.should eq("documents/allocations/#{allocation.id}")

  page.should have_selector("span[@id='page-title']")
  within('#page-title') do
    page.should have_content(
      "#{I18n.t('views.allocations.page_title_show')}")
  end

  within("#container_documents form") do
    find("#created")[:value].should eq(allocation.created.strftime("%d.%m.%Y"))
    find("#storekeeper_entity")[:value].should eq(allocation.storekeeper.tag)
    find("#storekeeper_place")[:value].should eq(allocation.storekeeper_place.tag)
    find("#foreman_entity")[:value].should eq(allocation.foreman.tag)
    find("#foreman_place")[:value].should eq(allocation.foreman_place.tag)
    find("#state")[:value].should eq(I18n.t('views.statable.inwork'))

    find("#created")[:disabled].should be_true
    find("#storekeeper_entity")[:disabled].should be_true
    find("#storekeeper_place")[:disabled].should be_true
    find("#foreman_entity")[:disabled].should be_true
    find("#foreman_place")[:disabled].should be_true
    find("#state")[:disabled].should be_true
    page.should have_no_selector("#motion-allocation")
  end

  within("#selected-resources tbody") do
    all(:xpath, './/tr').count.should eq(allocation.items.count)
    all(:xpath, './/tr').each_with_index do |tr, idx|
      tr.should have_content(allocation.items[idx].resource.tag)
      tr.should have_content(allocation.items[idx].resource.mu)
      tr.find(:xpath, './/input')[:value].to_f.should eq(allocation.items[idx].amount)
    end
  end
end

def should_present_allocation(allocations)
  check_group_content("#container_documents table", allocations) do |allocation|
    state =
        case allocation.state
          when Statable::UNKNOWN then I18n.t('views.statable.unknown')
          when Statable::INWORK then I18n.t('views.statable.inwork')
          when Statable::CANCELED then I18n.t('views.statable.canceled')
          when Statable::APPLIED then I18n.t('views.statable.applied')
        end
    [allocation.created.strftime('%Y-%m-%d'), allocation.storekeeper.tag,
     allocation.storekeeper_place.tag, allocation.foreman.tag, state]
  end
end

def should_present_warehouse(warehouse)
  page.should have_content(warehouse.tag)
  page.should have_content(warehouse.exp_amount.to_i)
  page.should have_content(warehouse.mu)
end

feature 'allocation', %q{
  As an user
  I want to view allocations
} do

  before :each do
    create(:chart)
  end

  scenario 'view allocations', js: true do
    per_page = Settings.root.per_page
    user = create(:user)
    credential = create(:credential, user: user, document_type: Allocation.name)
    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
    (per_page + 1).times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click
    current_hash.should eq('documents/allocations/new')

    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.save')}']")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.back')}']")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.draft')}']")
    page.should have_xpath("//div[@class='paginate' and contains(@style, 'display: none')]")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    page.should have_selector("span[@id='page-title']")
    within('#page-title') do
      page.should have_content("#{I18n.t('views.allocations.page_title_new')}")
    end

    page.should have_datepicker("created")
    page.datepicker("created").prev_month.day(10)

    within("#container_documents form") do
      page.should have_no_selector('#available-resources tbody tr')

      find('#storekeeper_place')[:disabled].should eq("true")
      find('#foreman_place')[:disabled].should eq("true")
      fill_in('storekeeper_entity', with: 'fail')
      page.has_css?("#storekeeper_entity", value: '').should be_true
      page.should have_no_selector('#available-resources tbody tr')

      fill_in('storekeeper_entity', with: 'fail')
      page.has_css?("#storekeeper_place", value: '').should be_true
      page.has_css?("#foreman_place", value: '').should be_true
      page.should have_no_selector('#available-resources tbody tr')

      3.times do
        user = create(:user)
        create(:credential, user: user, document_type: Allocation.name)
      end
      3.times { create(:user) }
      items = Credential.where(document_type: Allocation.name).
          all.collect { |c| c.user.entity }
      check_autocomplete("storekeeper_entity", items, :tag, true)
      fill_in_autocomplete('storekeeper_entity', items[0].tag)
      find("#storekeeper_entity")[:value].should eq(items[0].tag)
      find("#storekeeper_place")[:value].should eq(
        User.where(entity_id: items[0].id).first.
          credentials.where(document_type: Allocation.name).first.place.tag)
      find("#foreman_place")[:value].should eq(
        User.where(entity_id: items[0].id).first.
          credentials.where(document_type: Allocation.name).first.place.tag)

      page.should have_selector("#motion-allocation")
      find('#motion-warehouse').click
      find("#foreman_place")[:value].should eq('')
      find("#foreman_entity")[:value].should eq('')
      check_autocomplete("foreman_entity", items, :tag, true)
      fill_in_autocomplete('foreman_entity', items[2].tag)
      find("#foreman_place")[:value].should eq(
        User.where(entity_id: items[2].id).first.
          credentials.where(document_type: Allocation.name).first.place.tag)
      find('#motion-allocation').click
      find("#foreman_entity")[:value].should eq('')
      find("#foreman_place")[:value].should eq(
        User.where(entity_id: items[0].id).first.
          credentials.where(document_type: Allocation.name).first.place.tag)

      items = Entity.all(order: :tag, limit: 5)
      check_autocomplete("foreman_entity", items, :tag)
    end

    unless page.find("#storekeeper_entity").value == wb.storekeeper.tag
      fill_in_autocomplete('storekeeper_entity', wb.storekeeper.tag)
    end

    wh = Warehouse.
        all(per_page: per_page, page: 1,
            where: { storekeeper_id: { equal: wb.storekeeper.id },
                     storekeeper_place_id: { equal: wb.storekeeper_place.id }})
    count = Warehouse.
        count(where: { storekeeper_id: { equal: wb.storekeeper.id },
                       storekeeper_place_id: { equal: wb.storekeeper_place.id }})

    check_content("#available-resources", wh) do |w|
      [w.tag, w.mu, w.real_amount.to_i]
    end

    wh_tag = Warehouse.
        all(per_page: per_page, page: 1,
            where: { storekeeper_id: { equal: wb.storekeeper.id },
                     storekeeper_place_id: { equal: wb.storekeeper_place.id }},
            where: { tag: { like: '1'}})
    wh_mu = Warehouse.
        all(per_page: per_page, page: 1,
            where: { storekeeper_id: { equal: wb.storekeeper.id },
                     storekeeper_place_id: { equal: wb.storekeeper_place.id }},
            where: { mu: { like: '1'}})
    wh_exp_amount = Warehouse.
        all(per_page: per_page, page: 1,
            where: { storekeeper_id: { equal: wb.storekeeper.id },
                     storekeeper_place_id: { equal: wb.storekeeper_place.id }},
            where: { exp_amount: { like: '2'}})

    page.find('#search_available_resources').click
    page.should have_selector("table[@id='available-resources'] thead tr[@id='resource_filter']")

    within('#available-resources') do
      within("thead tr[@id='resource_filter']") do
        fill_in 'resource_filter_tag', with: '1'
      end
      page.find('#filtrate').click

      page.all('tbody tr').each_with_index { |tr, i|
        tr.find("td[@data-bind='text: tag']").should have_content(wh_tag[i].tag)
      }

      within("thead tr[@id='resource_filter']") do
        fill_in 'resource_filter_tag', with: ''
        fill_in 'resource_filter_mu', with: '1'
      end
      page.find('#filtrate').click

      page.all('tbody tr').each_with_index { |tr, i|
        tr.find("td[@data-bind='text: mu']").should have_content(wh_mu[i].mu)
      }

      within("thead tr[@id='resource_filter']") do
        fill_in 'resource_filter_mu', with: ''
        fill_in 'resource_filter_exp_amount', with: '2'
      end
      page.find('#filtrate').click

      page.all('tbody tr').each_with_index { |tr, i|
        tr.find("td[@data-bind='text: exp_amount']").
            should have_content(wh_exp_amount[i].exp_amount.to_i)
      }
    end
    page.find('#search_available_resources').click
    page.should_not have_selector("#available-resources thead tr[@id='resource_filter']",
                                  visible: true)

    next_page("#available-resources div[@class='paginate']")

    within("#available-resources div[@class='paginate']") do
      find_button('>')[:disabled].should eq('true')
    end

    wh = Warehouse.
        all(per_page: per_page, page: 2,
            where: { storekeeper_id: { equal: wb.storekeeper.id },
                     storekeeper_place_id: { equal: wb.storekeeper_place.id }})

    check_content("#available-resources", wh) do |w|
      [w.tag, w.mu, w.real_amount.to_i]
    end

    prev_page("#available-resources div[@class='paginate']")

    within("#selected-resources") do
      page.should_not have_selector('tbody tr')
    end

    within("#container_documents") do
      (0..count-1).each do |i|
        page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
        if i < count - 1
          if i < count - per_page
            page.should have_selector('#available-resources tbody tr', count: per_page)
          else
            page.should have_selector('#available-resources tbody tr', count: count-i-1)
          end
        else
          page.should_not have_selector('#available-resources tbody tr')
        end
        page.should have_selector('#selected-resources tbody tr', count: 1+i)
      end
    end

    within("#available-resources") do
      page.all('tbody tr').each_with_index { |tr, i|
        tr.find("td input[@type='text']")[:value].should eq("#{100+i}")
      }
    end

    wb2 = build(:waybill)
    wb2.add_item(tag: "resource_2", mu: "mu_2", amount: 100, price: 10)
    wb2.save!
    wb2.apply

    wbs = Waybill.
        in_warehouse(where: { storekeeper_id: { equal: wb.storekeeper.id },
                              storekeeper_place_id: { equal: wb.storekeeper_place.id }})

    page.find('#mode-waybills').click

    check_content("#available-resources-by-wb", wbs) do |w|
      [w.document_id, w.created.strftime('%Y-%m-%d'), w.distributor.name,
       w.storekeeper.tag, w.storekeeper_place.tag]
    end

    page.find("#available-resources-by-wb td[@class='allocation-tree-actions-by-wb']").click

    items = wbs[0].items[0, per_page]
    count = wbs[0].items.length

    check_content("#available-resources-by-wb table", items) do |item|
      [item.resource.tag, item.resource.mu, item.amount.to_i]
    end

    check_paginate("#available-resources-by-wb div[@class='paginate']", count, per_page)

    next_page("#available-resources-by-wb div[@class='paginate']")

    items = wbs[0].items[per_page, per_page]

    check_content("#available-resources-by-wb table", items) do |item|
      [item.resource.tag, item.resource.mu, item.amount.to_i]
    end

    check_content("#selected-resources", wb.items) do |item|
      [item.resource.tag, item.resource.mu, item.amount.to_i]
    end

    page.find('#mode-resources-by-wb').click
    page.should have_no_selector('#available-resources-by-wb')

    (0..count-1).each do |i|
      page.find("#selected-resources tbody tr td[@class='allocation-actions'] span").click
      if i < count-1
        page.should have_selector('#selected-resources tbody tr', count: count-i-1)
        page.should have_selector('#available-resources tbody tr', count: 1+i)
      else
        page.should_not have_selector('#selected-resources tbody tr')
      end
    end

    wb3 = build(:waybill, storekeeper: wb.storekeeper,
                storekeeper_place: wb.storekeeper_place)
    wb3.add_item(tag: 'resource#0', mu: 'mu0', amount: 27, price: 10)
    wb3.save!
    wb3.apply.should be_true

    wbs = Waybill.
        in_warehouse(where: { storekeeper_id: { equal: wb.storekeeper.id },
                              storekeeper_place_id: { equal: wb.storekeeper_place.id }})

    page.find('#mode-waybills').click
    page.should have_no_selector('#available-resources')
    within('#available-resources-by-wb') do
      page.all('tbody tr').each do |tr|
        if tr.has_content?(wb.document_id)
          tr.find("td[@class='allocation-actions-by-wb'] span").click
        end
      end
      within('tbody') do
        if wbs.count - 1 > 0
          page.should have_selector('tr', count: wbs.count - 1, visible: true)
        else
          page.should_not have_selector('tr')
        end
      end
    end

    within('#selected-resources tbody') do
      page.all('tbody tr').each do |tr|
        if tr.has_content?('resource#0') &&
           tr.has_content?('mu0') &&
           tr.has_content?('127')
          tr.find('input')[:value].should eq('100')
        end
      end

      per_page.times do |i|
        if wb.items[i].resource.tag != "resource#0"
          page.should have_content(wb.items[i].resource.tag)
          page.should have_content(wb.items[i].resource.mu)
          page.should have_content(wb.items[i].amount.to_i)
        end
      end
    end

    within('#available-resources-by-wb') do
      all(:xpath, ".//tbody//tr", visible: true).each do |tr|
        if tr.has_content?(wb3.document_id)
          tr.find("td[@class='allocation-actions-by-wb'] span").click
        end
      end
    end

    within('#selected-resources') do
      page.all('tbody tr').each do |tr|
        if tr.has_content?('resource#0') &&
           tr.has_content?('mu0') &&
           tr.has_content?('127')
          tr.find('input')[:value].should eq('127')
        end
      end
    end
  end

  scenario 'sort resources on allocation creation page', js: true do
    user = create(:user)
    credential = create(:credential, user: user, document_type: Allocation.name)
    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
    wb.add_item(tag: "roof", mu: "m2", amount: 33, price: 23.5)
    wb.add_item(tag: "shovel", mu: "th", amount: 28, price: 34.2)
    wb.add_item(tag: "airbug", mu: "th", amount: 115, price: 1100.56)
    wb.save!
    wb.apply

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click
    current_hash.should eq('documents/allocations/new')

    fill_in_autocomplete('storekeeper_entity', wb.storekeeper.tag)

    within('#available-resources') do
      test_order = lambda do |field, type|
        warehouses = Warehouse.
            all(where: { storekeeper_id: { equal: wb.storekeeper.id },
                         storekeeper_place_id: { equal: wb.storekeeper_place.id }},
                order_by: { field: field, type: type })
        count = Warehouse.
                count(where: { storekeeper_id: { equal: wb.storekeeper.id },
                               storekeeper_place_id: { equal: wb.storekeeper_place.id }})
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

      test_order.call('tag','asc')
      test_order.call('tag','desc')

      test_order.call('mu','asc')
      test_order.call('mu','desc')

      test_order.call('exp_amount','asc')
      test_order.call('exp_amount','desc')
    end
  end

  scenario 'test allocations save', js: true do
    PaperTrail.enabled = true

    user = create(:user)
    credential = create(:credential, user: user, document_type: Allocation.name)
    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place,
                         created: DateTime.current.change(year: 2011))
    wb.add_item(tag: 'roof', mu: 'm2', amount: 12, price: 100.0)
    wb.add_item(tag: 'roof2', mu: 'm2', amount: 12, price: 100.0)
    wb.save!
    wb.apply

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click

    click_button(I18n.t('views.allocations.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content(
          "#{I18n.t('views.allocations.created_at')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.allocations.storekeeper')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.allocations.foreman')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.datepicker("created").prev_month.day(10)

    within("#container_documents form") do
      fill_in_autocomplete('storekeeper_entity', wb.storekeeper.tag)
      fill_in("foreman_entity", :with =>"entity")
    end

    within("#container_documents") do
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click

      within('#selected-resources') do
        fill_in I18n.t('views.allocations.amount'), :with => 0
      end
    end

    click_button(I18n.t('views.allocations.save'))
    within('#container_documents') do
      within('#container_notification') do
        page.should have_content("#{I18n.t('views.allocations.amount')} : #{I18n.t(
            'errors.messages.greater_than', count: 0)}")
      end
      within('#selected-resources') do
        fill_in I18n.t('views.allocations.amount'), :with => -1
      end
    end

    click_button(I18n.t('views.allocations.save'))
    within('#container_documents') do
      within('#container_notification') do
        page.should have_content("#{I18n.t('views.allocations.amount')} : #{I18n.t(
            'errors.messages.greater_than', count: 0)}")
      end
      within('#selected-resources') do
        fill_in I18n.t('views.allocations.amount'), :with => 0.37
      end
    end

    lambda {
      click_button(I18n.t('views.allocations.save'))
      current_hash.should eq("documents/allocations/#{Allocation.last.id}")
    }.should change(Allocation, :count).by(1)

    PaperTrail.enabled = false
  end

  scenario 'save distibution by non root user', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill, created: DateTime.current.change(year: 2011))
    wb.add_item(tag: 'roof', mu: 'm2', amount: 12, price: 100.0)
    wb.add_item(tag: 'roof2', mu: 'm2', amount: 12, price: 100.0)
    wb.save!
    wb.apply

    password = "password"
    user = create(:user, password: password, entity: wb.storekeeper)
    create(:credential, place: wb.storekeeper_place, user: user,
                        document_type: Allocation.name)

    page_login user.email, password

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click

    within("#container_documents form") do
      page.datepicker("created").prev_month.day(10)
      find("#storekeeper_entity")[:value].should eq(user.entity.tag)
      find("#storekeeper_place")[:value].should eq(wb.storekeeper_place.tag)
      find("#foreman_place")[:value].should eq(wb.storekeeper_place.tag)
      find("#storekeeper_entity")[:disabled].should eq("true")
      find("#storekeeper_place")[:disabled].should eq("true")
      find("#foreman_place")[:disabled].should eq("true")
      fill_in("foreman_entity", :with =>"entity")
    end

    within("#container_documents") do
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
    end

    lambda {
      click_button(I18n.t('views.allocations.save'))
      current_hash.should eq("documents/allocations/#{Allocation.last.id}")
    }.should change(Allocation, :count).by(1)

    PaperTrail.enabled = false
  end

  scenario 'show allocations', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    (0..4).each do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    (0..4).each do |i|
      ds.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 10+i)
    end
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    show_allocation(ds)

    PaperTrail.enabled = false
  end

  scenario 'applying allocations', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    click_button(I18n.t('views.allocations.apply'))
    current_hash.should eq("documents/allocations/#{ds.id}")
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
      'views.allocations.apply')}' and contains(@style, 'display: none')]")
    PaperTrail.enabled = false
  end

  scenario 'canceling allocations', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    visit("#documents/allocations/#{ds.id}")
    click_button(I18n.t('views.allocations.cancel'))
    current_hash.should eq("documents/allocations/#{ds.id}")
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.allocations.cancel')}' and contains(@style, 'display: none')]")
    find_field('state').value.should eq(I18n.t('views.statable.canceled'))
    click_link I18n.t('views.home.logout')

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!
    ds.apply

    page_login

    visit("#documents/allocations/#{ds.id}")
    click_button(I18n.t('views.allocations.cancel'))
    current_hash.should eq("documents/allocations/#{ds.id}")
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.allocations.cancel')}' and contains(@style, 'display: none')]")
    find_field('state').value.should eq(I18n.t('views.statable.reversed'))
    click_link I18n.t('views.home.logout')

    PaperTrail.enabled = false
  end

  scenario 'generate pdf', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
                      'Allocation - #{wb.storekeeper.tag}')]").click

    visit("#{allocation_path(ds)}.html")

    page.should have_selector("span [@class='description_element']")

    within('#person-list') do
      page.should have_content("#{ds.storekeeper.tag}")
      page.should have_content("#{ds.foreman.tag}")
    end

    within("table[@class='allocations'] tbody tr") do
      page.should have_content("test resource")
      page.should have_content("test mu")
      page.should have_content("10")
    end

    within("div[@class='date-block']") do
      page.should have_content(ds.created.strftime('%Y-%m-%d'))
    end

    within('#signature') do
      page.should have_content("#{ds.storekeeper.tag}")
      page.should have_content("#{ds.foreman.tag}")
    end

    PaperTrail.enabled = false
  end

  scenario 'view allocations', js: true do
    per_page = Settings.root.per_page

    (per_page + 1).times do |i|
      wb = build(:waybill)
      wb.add_item(tag: "test resource##{i}", mu: "test mu", amount: 200+i, price: 100+i)
      wb.save!
      wb.apply

      ds = build(:allocation, storekeeper: wb.storekeeper,
                 storekeeper_place: wb.storekeeper_place)
      ds.add_item(tag: "test resource##{i}", mu: "test mu", amount: 10)
      ds.save!
    end

    allocations = Allocation.limit(per_page)
    count = Allocation.count

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
      "not(contains(@style, 'display: none'))]/li[@id='allocations']/a").click

    current_hash.should eq('allocations')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
      "/ul[@id='slide_menu_deals']" +
      "/li[@id='allocations' and @class='sidebar-selected']")

    titles = [I18n.t('views.allocations.created_at'),
              I18n.t('views.allocations.storekeeper'),
              I18n.t('views.allocations.storekeeper_place'),
              I18n.t('views.allocations.foreman'),
              I18n.t('views.statable.state')]
    check_header("#container_documents table", titles)

    page.find("#show-filter").click
    within('#filter-area') do
      titles.each do |title|
        page.should have_content(title)
      end

      fill_in('filter_created_at', with: allocations[3].created.strftime('%Y-%m-%d'))
      fill_in('filter_foreman', with: allocations[3].foreman.tag)
      fill_in('filter_storekeeper', with: allocations[3].storekeeper.tag)
      fill_in('filter_storekeeper_place', with: allocations[3].storekeeper_place.tag)
      fill_in('filter_resource', with: allocations[3].items[0].resource.tag)
      select(I18n.t('views.statable.inwork'), from: 'filter_state')

      click_button(I18n.t('views.home.search'))
    end

    should_present_allocation([allocations[3]])
    check_paginate("div[@class='paginate']", 1, 1)

    page.find("#show-filter").click
    within('#filter-area') do
      fill_in('filter_created_at', with: "")
      fill_in('filter_foreman', with: "")
      fill_in('filter_storekeeper', with: "")
      fill_in('filter_storekeeper_place', with: "")
      fill_in('filter_resource', with: "")
      select('', from: 'filter_state')

      click_button(I18n.t('views.home.search'))
    end

    should_present_allocation(allocations)
    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    allocations = Allocation.limit(per_page).offset(per_page)
    should_present_allocation(allocations)
    prev_page("div[@class='paginate']")

    page.find(:xpath, "//table//tbody//tr[1]//td[2]").click
    show_allocation(Allocation.first)
  end

  scenario "storekeeper should view only items created by him", js: true do
    PaperTrail.enabled = true

    Waybill.delete_all
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Waybill.name)
    page_login user.email, password

    12.times do |i|
      wb = build(:waybill, storekeeper: i % 2 == 0 ? user.entity : create(:entity),
                       storekeeper_place: i % 4 == 0 ? credential.place : create(:place))
      wb.add_item(tag: "test resource##{i}", mu: "test mu", amount: 200+i, price: 100+i)
      wb.save!
      wb.apply

      ds = build(:allocation, storekeeper: wb.storekeeper,
                 storekeeper_place: wb.storekeeper_place)
      ds.add_item(tag: "test resource##{i}", mu: "test mu", amount: 10)
      ds.save!
    end

    allocations = Allocation.by_storekeeper(user.entity).
                             by_storekeeper_place(credential.place)
    allocations.count.should eq(3)
    allocations_not_visible = Allocation.where{id.not_in(allocations.select(:id))}

    page.find('#btn_slide_lists').click
    page.find(:xpath, "//ul//li[@id='allocations']/a").click

    current_hash.should eq('allocations')
    page.should have_xpath("//ul//li[@id='allocations' and @class='sidebar-selected']")

    within('#container_documents table') do
      within('tbody') do
        allocations.each do |allocation|
          page.should have_content(allocation.created.strftime('%Y-%m-%d'))
          page.should have_content(allocation.storekeeper.tag)
          page.should have_content(allocation.storekeeper_place.tag)
          page.should have_content(allocation.foreman.tag)
          state =
            case allocation.state
              when Statable::UNKNOWN then I18n.t('views.statable.unknown')
              when Statable::INWORK then I18n.t('views.statable.inwork')
              when Statable::CANCELED then I18n.t('views.statable.canceled')
              when Statable::APPLIED then I18n.t('views.statable.applied')
            end
          page.should have_content(state)
        end
        allocations_not_visible.each do |allocation|
          page.should_not have_content(allocation.foreman.tag)
        end
      end
    end
    click_link I18n.t('views.home.logout')

    password = "password"
    user = create(:user, password: password, entity: Waybill.first.storekeeper)
    page_login user.email, password

    page.find('#btn_slide_lists').click
    page.find(:xpath, "//ul//li[@id='allocations']/a").click

    current_hash.should eq('allocations')
    page.should have_xpath("//ul//li[@id='allocations' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.should_not have_selector("tr")
    end

    PaperTrail.enabled = false
  end

  scenario "views allocation's resources'", js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    (per_page + 1).times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu##{i}", amount: 200+i, price: 100+i)
    end
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
               storekeeper_place: wb.storekeeper_place)
    (per_page + 1).times do |i|
      ds.add_item(tag: "resource##{i}", mu: "mu##{i}", amount: 100)
    end
    ds.save!

    allocation = Allocation.first

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
        "not(contains(@style, 'display: none'))]/li[@id='allocations']/a").click

    current_hash.should eq('allocations')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/ul[@id='slide_menu_deals']" +
                           "/li[@id='allocations' and @class='sidebar-selected']")

    should_present_allocation([allocation])

    within('#container_documents table tbody') do
      page.should have_selector(:xpath, ".//tr//td[@class='tree-actions']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']", count: 1)
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions']").click
    end

    count = allocation.items.count
    resources = allocation.items[0, per_page]
    count.should eq(per_page + 1)

    check_paginate("#resource_#{allocation.id} div[@class='paginate']",
                   count, per_page)
    check_content("#resource_#{allocation.id} table[@class='inner-table']",
                  resources) do |res|
      [res.resource.tag, res.resource.mu, res.amount.to_i]
    end
    next_page("#resource_#{allocation.id} div[@class='paginate']")
    resources = allocation.items[per_page, per_page]
    check_content("#resource_#{allocation.id} table[@class='inner-table']",
                  resources) do |res|
      [res.resource.tag, res.resource.mu, res.amount.to_i]
    end

    within('#container_documents table tbody') do
      find(:xpath, ".//tr[1]//td[@class='tree-actions']").click
      page.find("#resource_#{allocation.id}").visible?.should_not be_true
    end
  end

  scenario 'sort allocations', js: true do
    moscow = create(:place, tag: 'Moscow')
    kiev = create(:place, tag: 'Kiev')
    amsterdam = create(:place, tag: 'Amsterdam')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')
    antonov = create(:entity, tag: 'Antonov')
    ivanov_legal = create(:legal_entity, name: 'Ivanov')
    petrov_legal = create(:legal_entity, name: 'Petrov')
    antonov_legal = create(:legal_entity, name: 'Antonov')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 1,
                distributor: petrov_legal, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 3,
                distributor: antonov_legal, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 2,
                distributor: ivanov_legal, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb3.save!
    wb3.apply

    al1 = build(:allocation, created: Date.new(2011,11,11),
                storekeeper: wb1.storekeeper,
                storekeeper_place: wb1.storekeeper_place,
                foreman: ivanov)
    al1.add_item(tag: 'roof', mu: 'rm', amount: 15)
    al1.save!
    al1.apply

    al2 = build(:allocation, created: Date.new(2011,11,12),
                storekeeper: wb2.storekeeper,
                storekeeper_place: wb2.storekeeper_place,
                foreman: petrov)
    al2.add_item(tag: 'roof', mu: 'rm', amount: 16)
    al2.save!

    al3 = build(:allocation, created: Date.new(2011,11,13),
                storekeeper: wb3.storekeeper,
                storekeeper_place: wb3.storekeeper_place,
                foreman: antonov)
    al3.add_item(tag: 'roof', mu: 'rm', amount: 17)
    al3.save!
    al3.apply

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
        "not(contains(@style, 'display: none'))]/li[@id='allocations']/a").click

    current_hash.should eq('allocations')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/ul[@id='slide_menu_deals']" +
                           "/li[@id='allocations' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
      allocations = Allocation.order_by(field: field, type: type).all
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
      should_present_allocation(allocations)
    end

    test_order.call('created','asc')
    test_order.call('created','desc')

    test_order.call('storekeeper','asc')
    test_order.call('storekeeper','desc')

    test_order.call('storekeeper_place','asc')
    test_order.call('storekeeper_place','desc')

    test_order.call('foreman','asc')
    test_order.call('foreman','desc')

    test_order.call('state','asc')
    test_order.call('state','desc')
  end
end
