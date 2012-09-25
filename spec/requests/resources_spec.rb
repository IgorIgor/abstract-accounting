# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'assets', %q{
  As an user
  I want to view assets
} do

  before :each do
    create(:chart)
  end

  scenario 'view assets', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:asset) }
    create(:money)

    resources = Resource.filtrate(paginate: {page: 1, per_page: per_page}).all
    count = Resource.count

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.resources')
    current_hash.should eq('resources')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                            "//li[@id='resources' and @class='sidebar-selected']")

    titles = [I18n.t('views.resources.tag'), I18n.t('views.resources.ext_info'),
              I18n.t('views.resources.type')]

    check_header("#container_documents table", titles)

    check_content("#container_documents table", resources) do |res|
      [res.tag, res.ext_info, I18n.t("activerecord.models.#{res.type.tableize.singularize}")]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")


    resources = Resource.filtrate(paginate: {page: 2, per_page: per_page}).all

    check_content("#container_documents table", resources) do |res|
      [res.tag, res.ext_info, I18n.t("activerecord.models.#{res.type.tableize.singularize}")]
    end
  end

  scenario 'view balances by asset', js: true do
    res2 = create(:asset)
    res = create(:asset)
    deal = create(:deal,
                   give: build(:deal_give, resource: res),
                   take: build(:deal_take, resource: res2),
                   rate: 10)
    create(:balance, side: Balance::PASSIVE, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.resources')
    current_hash.should eq('resources')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                           "//li[@id='resources' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[2]/td[1]").click
    end
    current_hash.should eq("balance_sheet?resource%5Bid%5D=#{res.id}&"+
                               "resource%5Btype%5D=#{res.class.name}")
    find('#slide_menu_conditions').visible?.should be_true
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      page.should have_content(deal.tag)
      page.should have_content(deal.entity.name)
      page.should have_content(res.tag)
    end
  end

  scenario 'create/edit asset', js: true do
    page_login
    page.find('#btn_slide_services').click
    page.find('#arrow_resources_actions').click
    click_link I18n.t('views.home.asset')
    current_hash.should eq('documents/assets/new')
    page.should have_xpath("//li[@id='assets_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.resources.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.resources.tag')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('asset_tag', with: 'new asset')
    fill_in('asset_mu', with: 'mu')
    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/assets/#{Asset.last.id}"
    end.should change(Asset, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.resources.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/assets/#{Asset.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.resources.page.title.edit'))
    end

    find_field('asset_tag')[:disabled].should be_nil
    find_field('asset_mu')[:disabled].should be_nil

    fill_in('asset_tag', with: 'edited new asset')
    fill_in('asset_mu', with: 'edited mu')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/assets/#{Asset.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.resources.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('asset_tag')[:disabled].should eq("true")
    find_field('asset_mu')[:disabled].should eq("true")
    find_field('asset_tag')[:value].should eq('edited new asset')
    find_field('asset_mu')[:value].should eq('edited mu')
  end

  scenario 'create/edit money', js: true do
    page_login
    page.find('#btn_slide_services').click
    page.find('#arrow_resources_actions').click
    click_link I18n.t('views.home.money')
    current_hash.should eq('documents/money/new')
    page.should have_xpath("//li[@id='money_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.money.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.money.alpha_code')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('money_alpha_code', with: 'new money')
    fill_in('money_num_code', with: '303')
    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/money/#{Money.last.id}"
    end.should change(Money, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.money.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('money_alpha_code')[:disabled].should eq("true")
    find_field('money_num_code')[:disabled].should eq("true")
    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/money/#{Money.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.money.page.title.edit'))
    end

    find_field('money_alpha_code')[:disabled].should be_nil
    find_field('money_num_code')[:disabled].should be_nil

    fill_in('money_alpha_code', with: 'edited new money')
    fill_in('money_num_code', with: '304')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/money/#{Money.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.money.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('money_alpha_code')[:disabled].should eq("true")
    find_field('money_num_code')[:disabled].should eq("true")
    find_field('money_alpha_code')[:value].should eq('edited new money')
    find_field('money_num_code')[:value].should eq('304')
  end

  scenario "sort resources", js: true do
    create(:money)
    create(:asset)
    create(:asset)
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.resources')
    current_hash.should eq('resources')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='resources' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
      resources = Resource.sort(field, type)
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
      check_content("#container_documents table", resources.all) do |res|
        [res.tag, res.ext_info, I18n.t("activerecord.models.#{res.type.tableize.singularize}")]
      end
    end

    test_order.call('tag','asc')
    test_order.call('tag','desc')

    test_order.call('ext_info','asc')
    test_order.call('ext_info','desc')

    test_order.call('type','asc')
    test_order.call('type','desc')
  end
end
