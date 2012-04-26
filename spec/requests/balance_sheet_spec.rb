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
    10.times do |i|
      Factory(:balance, side: i % 2 == 0 ? Balance::ACTIVE : Balance::PASSIVE)
    end

    bs = BalanceSheet.all

    page_login
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
            page.should have_content(balance.value)
          end
        end
      end
    end

    page.should have_xpath("//div[@id='ui-datepicker-div']")
    page.find("#balance_date_start").click
    page.should have_xpath("//div[@id='ui-datepicker-div'" +
                               " and contains(@style, 'display: block')]")
    page.find("#container_documents").click
    page.should have_xpath("//div[@id='ui-datepicker-div'" +
                               " and contains(@style, 'display: none')]")

    page.find("#balance_date_start").click
    page.find(:xpath, "//div[@id='ui-datepicker-div']" +
        "/table[@class='ui-datepicker-calendar']/tbody/tr[2]/td[2]/a").click
    date = Date.parse(page.find("#balance_date_start")[:value])
    5.times do |i|
      bs[i].update_attributes(start: date)
    end
    date = date + 2
    (5..9).each do |i|
      bs[i].update_attributes(start: date)
    end
    page.find("#balance_date_start").click
    page.find(:xpath, "//div[@id='ui-datepicker-div']" +
        "/table[@class='ui-datepicker-calendar']/tbody/tr[2]/td[2]/a").click
    within("div[@id='main'] div[@id='container_documents'] table tbody") do
      5.times do |i|
        page.should have_content(bs[i].deal.tag)
      end
      (5..9).each do |i|
        page.should_not have_content(bs[i].deal.tag)
      end
    end
  end
end
