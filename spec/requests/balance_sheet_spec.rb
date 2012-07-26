# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "rspec"
require 'spec_helper'

feature "BalanceSheet", %q{
  As an user
  I want to view balance sheet
} do

  before :each do
    create(:chart)
  end

  scenario 'visit balance sheet page', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times do |i|
      create(:balance, side: i % 2 == 0 ? Balance::ACTIVE : Balance::PASSIVE, amount: 3.0)
    end

    bs = BalanceSheet.paginate(page: 1).all
    bs_count = BalanceSheet.db_count

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.balance_sheet')
    current_hash.should eq('balance_sheet')
    page.should have_xpath("//li[@id='balance_sheet' and @class='sidebar-selected']")

    titles = [
        I18n.t('views.balance_sheet.deal'),
        I18n.t('views.balance_sheet.entity'),
        I18n.t('views.balance_sheet.resource'),
        I18n.t('views.balance_sheet.place'),
        I18n.t('views.balance_sheet.debit'),
        I18n.t('views.balance_sheet.credit')
    ]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", bs) do |balance|
      if Balance::PASSIVE == balance.side
        find(:xpath, ".//td[5]").should have_content('')
      else
        find(:xpath, ".//td[4]").should have_content('')
      end
      [balance.deal.tag,
       balance.deal.entity.name,
       balance.deal.give.resource.tag,
       balance.deal.give.place.tag,
       balance.amount
      ]
    end

    within("div[@id='main'] div[@id='container_documents'] table tfoot tr") do
      page.should have_content(bs.liabilities.to_s)
      page.should have_content(bs.assets.to_s)
    end

    check_paginate("div[@class='paginate']", bs_count, per_page)
    next_page("div[@class='paginate']")
    bs = BalanceSheet.paginate(page: 2).all
    check_content("#container_documents table", bs) do |balance|
      if Balance::PASSIVE == balance.side
        find(:xpath, ".//td[5]").should have_content('')
      else
        find(:xpath, ".//td[4]").should have_content('')
      end
      [balance.deal.tag,
       balance.deal.entity.name,
       balance.deal.give.resource.tag,
       balance.deal.give.place.tag,
       balance.amount
      ]
    end

    date = DateTime.now.change(day: 10, hour: 12, min: 0, sec: 0).prev_month
    bs = BalanceSheet.paginate(page: 1).all
    half = (per_page / 2).round
    half.times do |i|
      bs[i].update_attributes(start: date)
    end
    (half..per_page - 1).each do |i|
      bs[i].update_attributes(start: date + 2)
    end
    page.should have_datepicker("balance_date_start")
    page.datepicker("balance_date_start").prev_month.day(10)

    bs = BalanceSheet.date(date).all
    bs_count = BalanceSheet.date(date).db_count
    check_content("#container_documents table", bs) do |balance|
      if Balance::PASSIVE == balance.side
        find(:xpath, ".//td[5]").should have_content('')
      else
        find(:xpath, ".//td[4]").should have_content('')
      end
      [balance.deal.tag,
       balance.deal.entity.name,
       balance.deal.give.resource.tag,
       balance.deal.give.place.tag,
       balance.amount
      ]
    end

    within("div[@id='main'] div[@id='container_documents'] table tfoot tr") do
      page.should have_content(bs.liabilities.to_s)
      page.should have_content(bs.assets.to_s)
    end

    check_paginate("div[@class='paginate']", bs_count, per_page)

    within("div[@id='container_documents']")  do
      choose('natural_mu')
    end

    check_content("#container_documents table", bs) do |balance|
      [balance.amount]
    end

    within("div[@id='container_documents']")  do
      choose('currency_mu')
    end

    check_content("#container_documents table", bs) do |balance|
      [balance.value]
    end

    within("div[@id='main'] div[@id='container_documents'] table tfoot tr") do
      page.should have_content(bs.liabilities.to_s)
      page.should have_content(bs.assets.to_s)
    end
  end

  scenario 'show transcripts by selected balance', js: true do
    rub = Chart.first.currency
    aasii = create(:asset)
    share = create(:deal,
                   give: build(:deal_give, resource: aasii),
                   take: build(:deal_take, resource: rub),
                   rate: 10000)
    bank = create(:deal,
                  give: build(:deal_give, resource: rub),
                  take: build(:deal_take, resource: rub),
                  rate: 1)
    f = create(:fact, from: share, to: bank, resource: rub,
               amount: 10000)
    txn = create(:txn, fact: f)

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.balance_sheet')
    current_hash.should eq('balance_sheet')
    page.should have_xpath("//li[@id='balance_sheet' and @class='sidebar-selected']")

    check_content("#container_documents table", [share.balance, bank.balance]) do |balance|
      if Balance::PASSIVE == balance.side
        find(:xpath, ".//td[5]").should have_content('')
      else
        find(:xpath, ".//td[4]").should have_content('')
      end
      [balance.deal.tag,
       balance.deal.entity.name,
       balance.deal.give.resource.tag,
       balance.deal.give.place.tag,
       balance.amount
      ]
    end

    check("balance_#{share.balance.id}")
    click_button(I18n.t('views.balance_sheet.report_on_selected'))

    page.should have_xpath("//li[@id='transcripts' and @class='sidebar-selected']")
    find_field('deal_tag').value.should have_content(share.tag)

    check_content("#container_documents table", [txn]) do |t|
      if share.id == t.fact.to.id
        page.find(:xpath, ".//td[3]").should have_content(t.fact.amount)
        [t.fact.day.strftime('%Y-%m-%d'), t.fact.from.tag]
      else
        page.find(:xpath, ".//td[4]").should have_content(txn.fact.amount)
        [t.fact.day.strftime('%Y-%m-%d'), t.fact.to.tag]
      end
    end
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
    end
  end

  scenario 'show general ledger by selected balances', js: true do
    rub = Chart.first.currency
    aasii = create(:asset)
    share = create(:deal,
                   give: build(:deal_give, resource: aasii),
                   take: build(:deal_take, resource: rub),
                   rate: 10000)
    bank = create(:deal,
                  give: build(:deal_give, resource: rub),
                  take: build(:deal_take, resource: rub),
                  rate: 1)
    f = create(:fact, from: share, to: bank, resource: rub,
               amount: 10000)
    txn = create(:txn, fact: f)

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.balance_sheet')
    current_hash.should eq('balance_sheet')
    page.should have_xpath("//li[@id='balance_sheet' and @class='sidebar-selected']")

    check_content("#container_documents table", [share.balance, bank.balance]) do |balance|
      if Balance::PASSIVE == balance.side
        find(:xpath, ".//td[5]").should have_content('')
      else
        find(:xpath, ".//td[4]").should have_content('')
      end
      [balance.deal.tag,
       balance.deal.entity.name,
       balance.deal.give.resource.tag,
       balance.deal.give.place.tag,
       balance.amount
      ]
    end

    check("balance_#{share.balance.id}")
    check("balance_#{bank.balance.id}")
    click_button(I18n.t('views.balance_sheet.report_on_selected'))

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    check_content("#container_documents table", [txn], 2) do |t, i|
      if i % 2 == 0
        [t.fact.day.strftime('%Y-%m-%d'),
         t.fact.amount.to_s,
         t.fact.resource.tag,
         t.fact.to.tag,
         t.value,
         t.earnings]
      elsif txn.fact.from
        [t.fact.from.tag,
         t.value,
         t.earnings]
      else
        []
      end
    end
  end

  scenario 'grouping balance sheet', js: true do
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
    page.find('#balance_sheet a').click
    current_hash.should eq('balance_sheet')

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: per_page)
    end

    select(I18n.t('views.balance_sheet.group_place'), from: 'balance_sheet_group')

    places = BalanceSheet.group_by('place').date(DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])
    places.length.should eq(4)

    within('#container_documents table tbody') do
      sleep(1)
      page.should have_selector('tr', count: places.count, visible: true)
      page.should have_content(wb.storekeeper_place.tag)
      page.should have_content(wb2.storekeeper_place.tag)
      page.should have_content(wb.distributor_place.tag)
      page.should have_content(wb2.distributor_place.tag)
      page.should have_selector(:xpath,
                                ".//tr//td[@class='tree-actions-by-wb']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']", count: 4)
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click

      balances = BalanceSheet.
          place_id(wb.distributor_place.id).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])


      check_paginate("#group_#{wb.distributor_place.id} div[@class='paginate']",
                     balances.count, per_page)
      check_content("#group_#{wb.distributor_place.id} table[@class='inner-table']",
                    balances) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true

      find(:xpath,
           ".//tr[5]//td[@class='tree-actions-by-wb']").click
      balances = BalanceSheet.
          place_id(wb2.distributor_place.id).
          paginate(page: 1, per_page: per_page).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])

      check_paginate("#group_#{wb2.distributor_place.id} div[@class='paginate']",
                     balances.db_count, per_page)
      check_content("#group_#{wb2.distributor_place.id} table[@class='inner-table']",
                    balances) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      next_page("#group_#{wb2.distributor_place.id} div[@class='paginate']")
      balances = BalanceSheet.
          place_id(wb2.distributor_place.id).
          paginate(page: 2, per_page: per_page).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])

      check_content("#group_#{wb2.distributor_place.id} table[@class='inner-table']",
                    balances) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      prev_page("#group_#{wb2.distributor_place.id} div[@class='paginate']")
      find(:xpath,
           ".//tr[5]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true
    end


    select(I18n.t('views.balance_sheet.group_resource'), from: 'balance_sheet_group')

    resources = BalanceSheet.group_by('resource').
        date( DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])
    resources.length.should eq(per_page + 2)

    check_paginate("div[@class='paginate']", resources.count, per_page)
    next_page("div[@class='paginate']")

    within('#container_documents table tbody') do
      sleep(1)
      page.should have_selector('tr', count: resources.count - per_page, visible: true)
      2.times do |i|
        page.should have_content(resources[per_page + i][:group_column])
      end
      page.should have_selector(:xpath, ".//tr//td[@class='tree-actions-by-wb']
          //div[@class='ui-corner-all ui-state-hover']
          //span[@class='ui-icon ui-icon-circle-plus']", count: 2)
    end

    prev_page("div[@class='paginate']")

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: per_page, visible: true)
      per_page.times do |i|
        page.should have_content(resources[i][:group_column])
      end
      page.should have_selector(:xpath, ".//tr//td[@class='tree-actions-by-wb']
          //div[@class='ui-corner-all ui-state-hover']
          //span[@class='ui-icon ui-icon-circle-plus']", count: per_page)
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click

      balances = BalanceSheet.
          resource(id: resources[0][:group_id], type: resources[0][:group_type]).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])

      check_paginate("#group_#{resources[0][:group_id]} div[@class='paginate']",
                     balances.db_count, per_page)
      check_content("#group_#{resources[0][:group_id]} table[@class='inner-table']",
                    balances[0, per_page]) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      next_page("#group_#{resources[0][:group_id]} div[@class='paginate']")
      check_content("#group_#{resources[0][:group_id]} table[@class='inner-table']",
                    balances[per_page, balances.length - per_page]) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      prev_page("#group_#{resources[0][:group_id]} div[@class='paginate']")
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{resources[0][:group_id]}").visible?.should_not be_true
    end

    select(I18n.t('views.balance_sheet.group_entity'), from: 'balance_sheet_group')

    entities = BalanceSheet.group_by('entity').
        date( DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])
    entities.length.should eq(4)


    check_paginate("div[@class='paginate']", entities.count, per_page)

    within('#container_documents table tbody') do
      sleep(1)
      page.should have_selector('tr', count: entities.length, visible: true)
      entities.each do |entity|
        page.should have_content(entity[:group_column])
      end
      page.should have_selector(:xpath, ".//tr//td[@class='tree-actions-by-wb']
          //div[@class='ui-corner-all ui-state-hover']
          //span[@class='ui-icon ui-icon-circle-plus']", count: entities.length)
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click

      balances = BalanceSheet.
          entity(id: entities[0][:group_id], type: entities[0][:group_type]).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])

      check_paginate("#group_#{entities[0][:group_id]} div[@class='paginate']",
                     balances.db_count, per_page)
      check_content("#group_#{entities[0][:group_id]} table[@class='inner-table']",
                    balances) do |balance|
        if Balance::PASSIVE == balance.side
          find(:xpath, ".//td[5]").should have_content('')
        else
          find(:xpath, ".//td[4]").should have_content('')
        end
        [balance.deal.tag,
         balance.deal.entity.name,
         balance.deal.give.resource.tag,
         balance.deal.give.place.tag,
         balance.amount
        ]
      end
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{entities[0][:group_id]}").visible?.should_not be_true
    end

    select(I18n.t('views.balance_sheet.group_place'), from: 'balance_sheet_group')

    balances = BalanceSheet.
        place_id(wb.storekeeper_place.id).
        date( DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])

    within('#container_documents table tbody') do
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      within("#group_#{wb.distributor_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")
        within("table[@class='inner-table'] tbody") do
          check("balance_#{balances[0].id}")
        end
      end
    end
    click_button(I18n.t('views.balance_sheet.report_on_selected'))
    page.should have_xpath("//li[@id='transcripts' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
    end

    click_link I18n.t('views.home.balance_sheet')
    select(I18n.t('views.balance_sheet.group_place'), from: 'balance_sheet_group')

    within('#container_documents table tbody') do
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click

      within("#group_#{wb.distributor_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")
        within("table[@class='inner-table'] tbody") do
          check("balance_#{balances[0].id}")
          check("balance_#{balances[1].id}")
        end
      end
    end
    click_button(I18n.t('views.balance_sheet.report_on_selected'))
    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 4)
    end
  end
end
