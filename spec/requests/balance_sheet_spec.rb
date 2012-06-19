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
    rub = create(:chart).currency
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
    rub = create(:chart).currency
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
end
