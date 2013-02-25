# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'places', %q{
  As an user
  I want to view places
} do

  before :each do
    create(:chart)
  end

  scenario 'view locals', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:local) }
    locals = Estimate::Local.limit(per_page).order("id ASC")
    count = Estimate::Local.count
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_locals')
    current_hash.should eq('estimate/locals')
    page.should have_xpath("//ul[@id='slide_menu_estimate']" +
                           "/li[@id='estimate_locals' and @class='sidebar-selected']")

    titles = [I18n.t('views.estimates.locals.tag'), I18n.t('views.estimates.locals.date'),
              I18n.t('views.estimates.locals.catalog')]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", locals) do |local|
      [local.tag, local.date.strftime('%Y-%m-%d'), local.catalog.tag]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    locals = Estimate::Local.limit(per_page).offset(per_page)
    check_content("#container_documents table", locals) do |local|
      [local.tag, local.date.strftime('%Y-%m-%d'), local.catalog.tag]
    end
    prev_page("div[@class='paginate']")
  end

  scenario 'create/edit local', js: true, focus: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate_local')
    current_hash.should eq('estimate/locals/new')

    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.locals.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.add'))[:disabled].should eq("true")

    find_field('local_date')[:value].should eq(Date.today.strftime('%d.%m.%Y'))

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.locals.tag')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.locals.catalog')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    2.times{ create(:catalog) }
    catalogs = Estimate::Catalog.order("id ASC").all
    catalog = catalogs[0]
    catalog2 = catalogs[1]
    catalog2.parent = catalog
    catalog2.save

    find('#local_catalog').click
    page.should have_selector('#catalogs_selector')
    within('#catalogs_selector') do
      within('table tbody') do
        within(:xpath, './/tr[1]//td[2]') do
          find("span[@class='cell-link']").click
        end
      end
    end
    page.should have_no_selector('#catalogs_selector')

    fill_in('local_tag', with: 'new local')

    page.should_not have_selector("#container_notification")

    within('fieldset table') do
      page.should_not have_selector('tbody tr')
    end

    3.times{ create(:bo_m) }
    boms = Estimate::BoM.order("id ASC").all
    boms[0].catalog = catalog
    boms[1].catalog = catalog
    boms[2].catalog = catalog2
    boms[0].save
    boms[1].save
    boms[2].save

    3.times{ create(:price_list) }
    price_lists = Estimate::PriceList.order("id ASC").all
    price_lists[0].catalog = catalog
    price_lists[0].bo_m = boms[0]
    price_lists[0].save
    price_lists[1].catalog = catalog
    price_lists[1].bo_m = boms[1]
    price_lists[1].save
    price_lists[2].catalog = catalogs[1]
    price_lists[2].bo_m = boms[2]
    price_lists[2].save

    find_button(I18n.t('views.users.add'))[:disabled].should be_nil
    click_button(I18n.t('views.users.add'))
    page.should have_selector('#boms_selector')
    within('#boms_selector') do
      within('table tbody') do
        all(:xpath, './/tr').count.should eq(3)
        all(:xpath, './/tr').each_with_index do |tr, i|
          tr.should have_content(boms[i].uid)
          tr.should have_content(boms[i].resource.tag)
          tr.should have_content(boms[i].resource.mu)
          tr.should_not have_content(boms[2].uid)
          tr.should_not have_content(boms[2].resource.tag)
          tr.should_not have_content(boms[2].resource.mu)
        end
        find(:xpath, './/tr[1]//td[1]').click
      end
    end
    page.should have_no_selector('#boms_selector')

    click_button(I18n.t('views.users.add'))
    page.should have_selector('#boms_selector')
    within('#boms_selector') do
      within('table tbody') do
        find(:xpath, './/tr[3]//td[1]').click
      end
    end
    page.should have_no_selector('#boms_selector')

    click_button(I18n.t('views.users.add'))
    page.should have_selector('#boms_selector')
    within('#boms_selector') do
      within('table tbody') do
        find(:xpath, './/tr[2]//td[1]').click
      end
    end
    page.should have_no_selector('#boms_selector')

    within('fieldset table tbody') do
      all(:xpath, './/tr').count.should eq(3)
      find(:xpath, './/tr[1]//td[1]//input')[:value].should eq(boms[0].uid)
      find(:xpath, './/tr[1]//td[2]//input')[:value].should eq(boms[0].resource.tag)
      find(:xpath, './/tr[1]//td[3]//input')[:value].should eq(boms[0].resource.mu)
      find(:xpath, './/tr[1]//td[4]//input')[:value].should eq('0')
      find(:xpath, './/tr[2]//td[1]//input')[:value].should eq(boms[2].uid)
      find(:xpath, './/tr[2]//td[2]//input')[:value].should eq(boms[2].resource.tag)
      find(:xpath, './/tr[2]//td[3]//input')[:value].should eq(boms[2].resource.mu)
      find(:xpath, './/tr[2]//td[4]//input')[:value].should eq('0')
      find(:xpath, './/tr[3]//td[1]//input')[:value].should eq(boms[1].uid)
      find(:xpath, './/tr[3]//td[2]//input')[:value].should eq(boms[1].resource.tag)
      find(:xpath, './/tr[3]//td[3]//input')[:value].should eq(boms[1].resource.mu)
      find(:xpath, './/tr[3]//td[4]//input')[:value].should eq('0')
    end

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t('views.waybills.item')}#0 #{I18n.t(
            'views.estimates.cost')} : #{I18n.t('errors.messages.greater_than', count: 0)}")
        page.should have_content("#{I18n.t('views.waybills.item')}#1 #{I18n.t(
            'views.estimates.cost')} : #{I18n.t('errors.messages.greater_than', count: 0)}")
        page.should have_content("#{I18n.t('views.waybills.item')}#2 #{I18n.t(
            'views.estimates.cost')} : #{I18n.t('errors.messages.greater_than', count: 0)}")
      end
    end

    find("#item_2 td[@class='table-actions'] label" ).click
    within('fieldset table tbody') do
      all(:xpath, './/tr').count.should eq(2)
    end

    fill_in('price_0', with: '10')
    fill_in('price_1', with: '11')

    page.should_not have_selector("#container_notification")

    #find('#local_catalog').click
    #page.should have_selector('#catalogs_selector')
    #within('#catalogs_selector') do
    #  within('table tbody') do
    #    within(:xpath, './/tr[2]//td[2]') do
    #      find("span[@class='cell-link']").click
    #    end
    #  end
    #end
    #page.should have_no_selector('#catalogs_selector')
    #wait_for_ajax
    #page.driver.browser.switch_to.alert.accept
    #page.evaluate_script('window.confirm = function() { return true; }')
    #
    #within('#item_0 tr') do
    #  within(:xpath, '.td[1]') do
    #    page.should have_selector("input [@class='error']")
    #  end
    #  within(:xpath, '.td[2]') do
    #    page.should have_selector("input [@class='error']")
    #  end
    #  within(:xpath, '.td[3]') do
    #    page.should have_selector("input [@class='error']")
    #  end
    #  within(:xpath, '.td[4]') do
    #    page.should have_selector("input [@class='error']")
    #  end
    #end

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "estimate/locals/#{Estimate::Local.last.id}"
    end.should change(Estimate::Local, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.locals.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_button(I18n.t('views.users.add'))[:disabled].should eq("true")
    find_field('local_tag')[:disabled].should eq("true")
    find_field('local_date')[:disabled].should eq("true")
    find_field('local_catalog')[:disabled].should eq("true")
    find_field('price_0')[:disabled].should eq("true")

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "estimate/locals/#{Estimate::Local.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.locals.page.title.edit'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.add'))[:disabled].should be_nil
    find_field('local_tag')[:disabled].should be_nil
    find_field('local_date')[:disabled].should be_nil
    find_field('local_catalog')[:disabled].should be_nil
    find_field('price_0')[:disabled].should be_nil

    within('fieldset table tbody') do
      all(:xpath, './/tr').count.should eq(2)
    end

    fill_in('local_tag', with: 'edited new local')
    #find('#local_catalog').click
    #page.should have_selector('#catalogs_selector')
    #within('#catalogs_selector') do
    #  within('table tbody') do
    #    within(:xpath, './/tr[2]//td[2]') do
    #      find("span[@class='cell-link']").click
    #    end
    #  end
    #end

    #page.driver.browser.switch_to.alert.accept

    find("#item_1 td[@class='table-actions'] label" ).click
    within('fieldset table tbody') do
      all(:xpath, './/tr').count.should eq(1)
    end

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "estimate/locals/#{Estimate::Local.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.locals.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_button(I18n.t('views.users.add'))[:disabled].should eq("true")

    find_field('local_tag')[:disabled].should eq("true")
    find_field('local_date')[:disabled].should eq("true")
    find_field('local_catalog')[:disabled].should eq("true")

    find_field('local_tag')[:value].should eq('edited new local')
    #find_field('local_date')[:value].should eq("true")
    #find_field('local_catalog')[:value].should eq(catalog[1].tag)

    within('fieldset table tbody') do
      all(:xpath, './/tr').count.should eq(1)
    end
  end
end
