# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'quote', %q{
  As an user
  I want to view quote
} do

  before :each do
    create(:chart)
  end

  scenario 'view quote', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:quote, money: create(:money)) }
    quote = Quote.limit(per_page).all
    count = Quote.count
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.quote')
    current_hash.should eq('quote')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/li[@id='quote' and @class='sidebar-selected']")

    titles = [I18n.t('views.quote.resource'), I18n.t('views.quote.date'),
              I18n.t('views.quote.rate')]

    check_header("#container_documents table", titles)
    check_content("#container_documents table", quote) do |item|
      [item.money.alpha_code, item.day.strftime('%Y-%m-%d'), item.rate.to_i]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    quote = Quote.limit(per_page).offset(per_page)
    check_content("#container_documents table", quote) do |item|
      [item.money.alpha_code, item.day.strftime('%Y-%m-%d'), item.rate.to_i]
    end

    prev_page("div[@class='paginate']")
    first_quote = Quote.first
    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[1]").click
    end
    current_hash.should eq("documents/quote/#{first_quote.id}")

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('quote_day')[:disabled].should eq("true")
    find_field('quote_rate')[:disabled].should eq("true")
    find_field('quote_money')[:disabled].should eq("true")
    find_field('quote_day')[:value].should eq(first_quote.day.strftime('%d.%m.%Y'))
    find_field('quote_rate')[:value].should eq(first_quote.rate.to_i.to_s)
    find_field('quote_money')[:value].should eq(first_quote.money.alpha_code)
  end

  scenario 'create/edit quote', js: true do
    page_login
    page.find('#btn_slide_services').click
    click_link I18n.t('views.home.quote')
    current_hash.should eq('documents/quote/new')
    page.should have_xpath("//li[@id='quote_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.quote.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.quote.date')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.quote.rate')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.quote.resource')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.should have_datepicker('quote_day')
    page.datepicker('quote_day').day(10)

    fill_in('quote_rate', with: '2')
    6.times { create(:money) }
    items = Money.order(:alpha_code).limit(6)
    check_autocomplete('quote_money', items, :alpha_code, true)
    page.should_not have_selector('#container_notification')

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/quote/#{Quote.last.id}"
    end.should change(Quote, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.quote.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('quote_day')[:disabled].should eq("true")
    find_field('quote_rate')[:disabled].should eq("true")
    find_field('quote_money')[:disabled].should eq("true")

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/quote/#{Quote.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.quote.page.title.edit'))
    end

    find_field('quote_day')[:disabled].should be_nil
    find_field('quote_rate')[:disabled].should be_nil
    find_field('quote_money')[:disabled].should be_nil
    page.datepicker('quote_day').day(22)
    new_date = DateTime.parse(find_field('quote_day')[:value])
    fill_in('quote_rate', with: '3')

    money = Quote.last.money

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/quote/#{Quote.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.quote.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('quote_day')[:disabled].should eq("true")
    find_field('quote_rate')[:disabled].should eq("true")
    find_field('quote_money')[:disabled].should eq("true")
    find_field('quote_day')[:value].should eq(new_date.strftime('%d.%m.%Y'))
    find_field('quote_rate')[:value].should eq('3')
    find_field('quote_money')[:value].should eq(money.alpha_code)
  end

  scenario 'sort quote', js: true do
    create(:quote, money: create(:money))
    create(:quote, money: create(:money))
    create(:quote, money: create(:money))
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.quote')
    current_hash.should eq('quote')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='quote' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
      quotes = Quote.sort(field, type)
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
      check_content("#container_documents table", quotes) do |quote|
        [quote.money.alpha_code, quote.day.strftime('%Y-%m-%d'), quote.rate.to_i]
      end
    end

    test_order.call('alpha_code','asc')
    test_order.call('alpha_code','desc')

    test_order.call('day','asc')
    test_order.call('day','desc')

    test_order.call('rate','asc')
    test_order.call('rate','desc')
  end
end
