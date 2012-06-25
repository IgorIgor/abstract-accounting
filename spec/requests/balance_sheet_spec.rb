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
        page.should have_content(I18n.t('views.balance_sheet.debit'))
        page.should have_content(I18n.t('views.balance_sheet.credit'))
      end

      within('tbody') do
        bs.each_with_index do |balance, idx|
          within(:xpath, ".//tr[#{idx + 1}]") do
            page.should have_content(balance.deal.tag)
            page.should have_content(balance.deal.entity.name)
            page.should have_content(balance.deal.give.resource.tag)
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

    date = DateTime.now.change(day: 10).prev_month
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
end
