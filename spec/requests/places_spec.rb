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

  scenario 'view places', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:place) }
    places = Place.limit(per_page)
    count = Place.count
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.places')
    current_hash.should eq('places')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/li[@id='places' and @class='sidebar-selected']")

    titles = [I18n.t('views.places.tag')]
    check_header("#container_documents table", titles)
    check_content("#container_documents table", places) do |place|
      [place.tag]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    places = Place.limit(per_page).offset(per_page)
    check_content("#container_documents table", places) do |place|
      [place.tag]
    end
  end

  scenario 'view balances by place', js: true do
    place = create(:place)
    place2 = create(:place)
    deal = create(:deal,
                  give: build(:deal_give, place: place),
                  take: build(:deal_take, place: place2),
                  rate: 10)
    create(:balance, side: Balance::PASSIVE, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.places')
    current_hash.should eq('places')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='places' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[1]").click
    end
    current_hash.should eq("balance_sheet?place_id=#{place.id}")
    find('#slide_menu_conditions').visible?.should be_true
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      page.should have_content(deal.tag)
      page.should have_content(deal.entity.name)
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").should have_content("1-1")
      find("span[@data-bind='text: count']").should have_content("1")
    end
  end

  scenario 'create/edit place', js: true do
    page_login
    page.find('#btn_slide_services').click
    click_link I18n.t('views.home.place')
    current_hash.should eq('documents/places/new')
    page.should have_xpath("//li[@id='places_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.places.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.places.tag')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('place_tag', with: 'new place')
    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/places/#{Place.last.id}"
    end.should change(Place, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.places.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('place_tag')[:disabled].should eq("true")
    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/places/#{Place.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.places.page.title.edit'))
    end

    find_field('place_tag')[:disabled].should be_nil

    fill_in('place_tag', with: 'edited new place')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/places/#{Place.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.places.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('place_tag')[:disabled].should eq("true")
    find_field('place_tag')[:value].should eq('edited new place')
  end
end
