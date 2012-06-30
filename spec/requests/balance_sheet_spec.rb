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

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.balance_sheet.deal'))
        page.should have_content(I18n.t('views.balance_sheet.entity'))
        page.should have_content(I18n.t('views.balance_sheet.resource'))
        page.should have_content(I18n.t('views.balance_sheet.place'))
        page.should have_content(I18n.t('views.balance_sheet.debit'))
        page.should have_content(I18n.t('views.balance_sheet.credit'))
      end

      within('tbody') do
        bs.each_with_index do |balance, idx|
          within(:xpath, ".//tr[#{idx + 1}]") do
            page.should have_content(balance.deal.tag)
            page.should have_content(balance.deal.entity.name)
            page.should have_content(balance.deal.give.resource.tag)
            page.should have_content(balance.deal.give.place.tag)
            if Balance::PASSIVE == balance.side
              find(:xpath, ".//td[5]").should have_content('')
            else
              find(:xpath, ".//td[4]").should have_content('')
            end
            page.should have_content(balance.amount)
          end
        end
      end
    end

    within("div[@id='main'] div[@id='container_documents'] table tfoot tr") do
      page.should have_content(bs.liabilities.to_s)
      page.should have_content(bs.assets.to_s)
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find("span[@data-bind='text: count']").
          should have_content(bs_count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    within("div[@class='paginate']") do
      click_button('>')

      to_range = (bs_count > per_page * 2) ? per_page * 2 : bs_count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(bs_count.to_s)

      find_button('<')[:disabled].should eq('false')
      click_button('<')

      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    date = DateTime.now.change(day: 10, hour: 12, min: 0, sec: 0).prev_month
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
    to_range = (bs_count > per_page) ? per_page : bs_count
    within("#container_documents table tbody") do
      bs.each do |item|
        page.should have_content(item.deal.tag)
      end
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(bs_count.to_s)

      find_button('<')[:disabled].should eq('true')
      if bs_count > per_page
        find_button('>')[:disabled].should eq('false')
      else
        find_button('>')[:disabled].should eq('true')
      end
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: to_range)
    end

    within("div[@id='container_documents']")  do
      choose('natural_mu')
    end

    within("div[@id='main'] div[@id='container_documents'] table tbody") do
      5.times do |i|
        page.should have_content(bs[i].amount)
      end
    end

    within("div[@id='container_documents']")  do
      choose('currency_mu')
    end

    within("div[@id='main'] div[@id='container_documents'] table tbody") do
      bs.each do |item|
        page.should have_content(item.value)
      end
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

    within('#container_documents table tbody') do
      within(:xpath, ".//tr[1]") do
        page.should have_content(share.tag)
        page.should have_content(share.entity.name)
        page.should have_content(share.give.resource.tag)
        page.should have_content(share.give.place.tag)
      end
    end

    check("balance_#{share.balance.id}")
    click_button(I18n.t('views.balance_sheet.report_on_selected'))

    page.should have_xpath("//li[@id='transcripts' and @class='sidebar-selected']")
    find_field('deal_tag').value.should have_content(share.tag)

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      page.should have_content(txn.fact.day.strftime('%Y-%m-%d'))
      if share.id == txn.fact.to.id
        page.find(:xpath, ".//tr[1]//td[3]").
            should have_content(txn.fact.amount)
        page.should have_content(txn.fact.from.tag)
      else
        page.find(:xpath, ".//tr[1]//td[4]").
            should have_content(txn.fact.amount)
        page.should have_content(txn.fact.to.tag)
      end
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

    within('#container_documents table tbody') do
      within(:xpath, ".//tr[1]") do
        page.should have_content(share.tag)
        page.should have_content(share.entity.name)
        page.should have_content(share.give.resource.tag)
        page.should have_content(share.give.place.tag)
      end
    end

    check("balance_#{share.balance.id}")
    check("balance_#{bank.balance.id}")
    click_button(I18n.t('views.balance_sheet.report_on_selected'))

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 2)
      page.should have_content(txn.fact.day.strftime('%Y-%m-%d'))
      page.should have_content(txn.fact.amount.to_s)
      page.should have_content(txn.fact.resource.tag)
      page.should have_content(txn.fact.from.tag)
      page.should have_content(txn.fact.to.tag)
      page.should have_content(txn.value)
      page.should have_content(txn.earnings)

      find(:xpath, ".//tr[1]//td[7]").should have_content('')
      find(:xpath, ".//tr[2]//td[6]").should have_content('')
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
      #page.all('tr').count.should eq(per_page)
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

      within("#group_#{wb.distributor_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{balances.length}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{balances.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('true')
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: balances.length)
          balances.each_with_index do |balance, idx|
            within(:xpath, ".//tr[#{idx + 1}]") do
              page.should have_content(balance.deal.tag)
              page.should have_content(balance.deal.entity.name)
              page.should have_content(balance.deal.give.resource.tag)
              page.should have_content(balance.deal.give.place.tag)
              if Balance::PASSIVE == balance.side
                find(:xpath, ".//td[5]").should have_content('')
              else
                find(:xpath, ".//td[4]").should have_content('')
              end
              page.should have_content(balance.amount)
            end
          end
        end
      end
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true

      find(:xpath,
           ".//tr[5]//td[@class='tree-actions-by-wb']").click
      balances = BalanceSheet.
          place_id(wb2.distributor_place.id).
          date( DateTime.now).
          all(include: [deal: [:entity, give: [:resource]]])

      within("#group_#{wb2.distributor_place.id}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{per_page}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{balances.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('false')
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: per_page)
          per_page.times do |i|
            within(:xpath, ".//tr[#{i + 1}]") do
              page.should have_content(balances[i].deal.tag)
              page.should have_content(balances[i].deal.entity.name)
              page.should have_content(balances[i].deal.give.resource.tag)
              page.should have_content(balances[i].deal.give.place.tag)
              if Balance::PASSIVE == balances[i].side
                find(:xpath, ".//td[5]").should have_content('')
              else
                find(:xpath, ".//td[4]").should have_content('')
              end
              page.should have_content(balances[i].amount)
            end
          end
        end
        within("div[@class='paginate']") do
          click_button('>')
          find_button('<')[:disabled].should eq('false')
          find_button('>')[:disabled].should eq('true')
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: 1)
          within(:xpath, ".//tr[1]") do
            page.should have_content(balances[per_page].deal.tag)
            page.should have_content(balances[per_page].deal.entity.name)
            page.should have_content(balances[per_page].deal.give.resource.tag)
            page.should have_content(balances[per_page].deal.give.place.tag)
            if Balance::PASSIVE == balances[per_page].side
              find(:xpath, ".//td[5]").should have_content('')
            else
              find(:xpath, ".//td[4]").should have_content('')
            end
            page.should have_content(balances[per_page].amount)
          end
        end
        within("div[@class='paginate']") do
          click_button('<')
          find_button('>')[:disabled].should eq('false')
          find_button('<')[:disabled].should eq('true')
        end
      end
      find(:xpath,
           ".//tr[5]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{wb2.storekeeper_place.id}").visible?.should_not be_true
    end


    select(I18n.t('views.balance_sheet.group_resource'), from: 'balance_sheet_group')

    resources = BalanceSheet.group_by('resource').
        date( DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])
    resources.length.should eq(per_page + 2)

    within("div[@class='paginate']") do
      within("span[@data-bind='text: range']") do
        page.should have_content("1-#{per_page}")
      end
      within("span[@data-bind='text: count']") do
        page.should have_content("#{per_page + 2}")
      end
      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
      click_button('>')
      find_button('<')[:disabled].should eq('false')
      find_button('>')[:disabled].should eq('true')
      within("span[@data-bind='text: range']") do
        page.should have_content("#{per_page + 1}-#{per_page + 2}")
      end
      within("span[@data-bind='text: count']") do
        page.should have_content("#{per_page + 2}")
      end
    end

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

    within("div[@class='paginate']") do
      click_button('<')
      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

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

      within("#group_#{resources[0][:group_id]}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{per_page}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{balances.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('false')
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: per_page)
          per_page.times do |i|
            within(:xpath, ".//tr[#{i + 1}]") do
              page.should have_content(balances[i].deal.tag)
              page.should have_content(balances[i].deal.entity.name)
              page.should have_content(balances[i].deal.give.resource.tag)
              page.should have_content(balances[i].deal.give.place.tag)
              if Balance::PASSIVE == balances[i].side
                find(:xpath, ".//td[5]").should have_content('')
              else
                find(:xpath, ".//td[4]").should have_content('')
              end
              page.should have_content(balances[i].amount)
            end
          end
        end
        within("div[@class='paginate']") do
          click_button('>')
          find_button('<')[:disabled].should eq('false')
          find_button('>')[:disabled].should eq('true')
          within("span[@data-bind='text: range']") do
            page.should have_content("#{per_page + 1}-#{balances.length}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{balances.length}")
          end
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: balances.length - per_page)
          (balances.length - per_page).times do |i|
            within(:xpath, ".//tr[#{i + 1}]") do
              page.should have_content(balances[i + per_page].deal.tag)
              page.should have_content(balances[i + per_page].deal.entity.name)
              page.should have_content(balances[i + per_page].deal.give.resource.tag)
              page.should have_content(balances[i + per_page].deal.give.place.tag)
              if Balance::PASSIVE == balances[i + per_page].side
                find(:xpath, ".//td[5]").should have_content('')
              else
                find(:xpath, ".//td[4]").should have_content('')
              end
              page.should have_content(balances[i + per_page].amount)
            end
          end
        end
        within("div[@class='paginate']") do
          click_button('<')
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('false')
        end
      end
      find(:xpath,
           ".//tr[1]//td[@class='tree-actions-by-wb']").click
      page.find("#group_#{resources[0][:group_id]}").visible?.should_not be_true
    end

    select(I18n.t('views.balance_sheet.group_entity'), from: 'balance_sheet_group')

    entities = BalanceSheet.group_by('entity').
        date( DateTime.now).
        all(include: [deal: [:entity, give: [:resource]]])
    entities.length.should eq(4)

    within("div[@class='paginate']") do
      within("span[@data-bind='text: range']") do
        page.should have_content("1-#{entities.length}")
      end
      within("span[@data-bind='text: count']") do
        page.should have_content("#{entities.length}")
      end
      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('true')
    end

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

      within("#group_#{entities[0][:group_id]}") do
        page.should have_selector("td[@class='td-inner-table']")

        within("div[@class='paginate']") do
          within("span[@data-bind='text: range']") do
            page.should have_content("1-#{balances.length}")
          end
          within("span[@data-bind='text: count']") do
            page.should have_content("#{balances.length}")
          end
          find_button('<')[:disabled].should eq('true')
          find_button('>')[:disabled].should eq('true')
        end
        within("table[@class='inner-table'] tbody") do
          page.should have_selector('tr', count: balances.length)
          balances.each_with_index do |balance, idx|
            within(:xpath, ".//tr[#{idx + 1}]") do
              page.should have_content(balance.deal.tag)
              page.should have_content(balance.deal.entity.name)
              page.should have_content(balance.deal.give.resource.tag)
              page.should have_content(balance.deal.give.place.tag)
              if Balance::PASSIVE == balance.side
                find(:xpath, ".//td[5]").should have_content('')
              else
                find(:xpath, ".//td[4]").should have_content('')
              end
              page.should have_content(balance.amount)
            end
          end
        end
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
