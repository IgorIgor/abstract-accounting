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

feature "GeneralLedger", %q{
  As an user
  I want to view general ledger
} do

  before :each do
    create(:chart)
  end

  scenario 'visit general ledger page', js: true do
    per_page = Settings.root.per_page
    wb = build(:waybill)
    per_page.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    gl = GeneralLedger.paginate(page: 1, per_page: Settings.root.per_page).all
    gl_count = GeneralLedger.count

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.general_ledger')
    current_hash.should eq('general_ledger')

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    titles = [
        I18n.t('views.general_ledger.date'),
        I18n.t('views.general_ledger.resource'),
        I18n.t('views.general_ledger.amount'),
        I18n.t('views.general_ledger.type'),
        I18n.t('views.general_ledger.account'),
        I18n.t('views.general_ledger.price'),
        I18n.t('views.general_ledger.debit'),
        I18n.t('views.general_ledger.credit')
    ]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", gl, 2) do |txn, i|
      if i % 2 == 0
        [txn.fact.day.strftime('%Y-%m-%d'),
         txn.fact.amount.to_s,
         txn.fact.resource.tag,
         txn.fact.to.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      elsif txn.fact.from
        [txn.fact.from.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      else
        []
      end
    end
    check_paginate("div[@class='paginate']", gl_count, per_page)
    next_page("div[@class='paginate']")

    gl = GeneralLedger.paginate(page: 2, per_page: Settings.root.per_page).all
    check_content("#container_documents table", gl, 2) do |txn, i|
      if i % 2 == 0
        [txn.fact.day.strftime('%Y-%m-%d'),
         txn.fact.amount.to_s,
         txn.fact.resource.tag,
         txn.fact.to.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      elsif txn.fact.from
        [txn.fact.from.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      else
        []
      end
    end

    GeneralLedger.paginate(page: 1, per_page: Settings.root.per_page).all.each do |txn|
      txn.fact.update_attributes(day: 1.months.since.change(day: 13))
    end

    page.should have_datepicker("general_ledger_date")
    page.datepicker("general_ledger_date").next_month.day(11)

    gl = GeneralLedger.on_date(1.months.since.change(day: 11).to_s).all
    check_content("#container_documents table", gl, 2) do |txn, i|
      if i % 2 == 0
        [txn.fact.day.strftime('%Y-%m-%d'),
         txn.fact.amount.to_s,
         txn.fact.resource.tag,
         txn.fact.to.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      elsif txn.fact.from
        [txn.fact.from.tag,
         ((txn.value + txn.earnings) / txn.fact.amount),
         txn.value + txn.earnings]
      else
        []
      end
    end
  end

  scenario "sort general_ledger", js: true do
    create(:chart)
    wb = build(:waybill)
    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    wb2 = build(:waybill)
    3.times do |i|
      wb2.add_item(tag: "resource2##{i}", mu: "mu2#{i}", amount: 200+i, price: 20+i)
    end
    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.general_ledger')
    current_hash.should eq('general_ledger')

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
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
      gl = GeneralLedger.on_date(nil).sort(field, type).all
      check_content("#container_documents table", gl, 2) do |txn, i|
        if i % 2 == 0
          [txn.fact.day.strftime('%Y-%m-%d'),
           txn.fact.amount.to_s,
           txn.fact.resource.tag,
           txn.fact.to.tag,
           ((txn.value + txn.earnings) / txn.fact.amount),
           txn.value + txn.earnings]
        elsif txn.fact.from
          [txn.fact.from.tag,
           ((txn.value + txn.earnings) / txn.fact.amount),
           txn.value + txn.earnings]
        else
          []
        end
      end
    end

    test_order.call('day','asc')
    test_order.call('day','desc')

    test_order.call('amount','asc')
    test_order.call('amount','desc')

    test_order.call('resource','asc')
    test_order.call('resource','desc')
  end
end
