# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'project', %q{
  As an user
  I want to view project
} do

  before :each do
    create :chart
    @ent = create :entity
    @le = create :legal_entity
    @pl = create :place
  end

  scenario 'create/show/edit project', js: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate.projects.new')
    current_hash.should eq('estimate/projects/new')
    page.should have_content(I18n.t('views.estimates.projects.customer'))
    page.should have_content(I18n.t('views.estimates.projects.place'))

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.projects.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    page.find("#legal_entity")[:disabled].should eq nil
    page.find("#ident_value")[:disabled].should eq nil
    page.find("#ident_value")[:readonly].should eq 'true'
    page.find("#place")[:disabled].should eq nil

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.legal_entities.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.legal_entities.identifier.vatin')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'activerecord.models.place')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.find("#legal_entity").click
    page.should have_selector('#legal_entities_selector')
    within('#legal_entities_selector') do
      within('table tbody') do
        find(:xpath, './/tr//td[1]').click
      end
    end
    page.should have_no_selector('#legal_entities_selector')

    click_link(I18n.t 'activerecord.models.entity')

    page.find("#entity")[:disabled].should eq nil
    page.find("#place")[:disabled].should eq nil

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.legal_entities.name')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.find("#entity").click
    page.should have_selector('#entities_selector')
    within('#entities_selector') do
      within('table tbody') do
        find(:xpath, './/tr//td[1]').click
      end
    end
    page.should have_no_selector('#entities_selector')

    page.find("#place").click
    page.should have_selector('#places_selector')
    within('#places_selector') do
      within('table tbody') do
        find(:xpath, './/tr//td[1]').click
      end
    end
    page.should have_no_selector('#places_selector')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    pr = Estimate::Project.last
    wait_until_hash_changed_to "estimate/projects/#{pr.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.projects.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq 'true'
    find_button(I18n.t('views.users.edit'))[:disabled].should eq nil
    page.find("#entity")[:disabled].should eq 'true'
    page.find("#place")[:disabled].should eq 'true'

    click_link(I18n.t 'activerecord.models.legal_entity')
    page.should_not have_selector('#legal_entity')

    find_field('entity')[:value].should eq pr.customer.tag
    find_field('place')[:value].should eq pr.place.tag
    find_field('entity')[:value].should eq @ent.tag
    find_field('place')[:value].should eq @pl.tag

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.projects.page.title.edit'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq "true"
    page.find("#entity")[:disabled].should eq nil
    page.find("#place")[:disabled].should eq nil

    click_link(I18n.t 'activerecord.models.legal_entity')

    page.find("#legal_entity")[:disabled].should eq nil
    page.find("#ident_value")[:disabled].should eq nil
    page.find("#legal_entity")[:value].should eq ''
    page.find("#ident_value")[:value].should eq ''
    page.find("#ident_value")[:readonly].should eq 'true'

    page.find("#legal_entity").click
    page.should have_selector('#legal_entities_selector')
    within('#legal_entities_selector') do
      within('table tbody') do
        find(:xpath, './/tr//td[1]').click
      end
    end
    page.should have_no_selector('#legal_entities_selector')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax

    wait_until_hash_changed_to "estimate/projects/#{pr.id}"
    pr = Estimate::Project.last

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.projects.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq 'true'
    find_button(I18n.t('views.users.edit'))[:disabled].should eq nil
    page.find("#legal_entity")[:disabled].should eq 'true'
    page.find("#place")[:disabled].should eq 'true'

    click_link(I18n.t 'activerecord.models.entity')
    page.should_not have_selector('#entity')

    find_field('legal_entity')[:value].should eq pr.customer.name
    find_field('place')[:value].should eq pr.place.tag
    find_field("ident_value")[:value].should eq pr.customer.identifier_value
    find_field('legal_entity')[:value].should eq @le.name
    find_field("ident_value")[:value].should eq @le.identifier_value
    find_field('place')[:value].should eq @pl.tag
  end

  scenario 'view projects page', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create :project }
    count = Estimate::Project.all.count
    prs = Estimate::Project.limit(per_page)

    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.projects')
    current_hash.should eq('estimate/projects')

    titles = [I18n.t('views.estimates.projects.customer'),
              I18n.t('views.estimates.projects.place')]
    wait_for_ajax
    check_header("#container_documents table", titles)
    check_content("#container_documents table", prs) do |pr|
      [pr.customer.tag, pr.place.tag]
    end
    check_paginate("div[@class='paginate']", count, per_page)

    find(:xpath, "//tr[1]/td[1]").click
    wait_for_ajax
    pr = Estimate::Project.first
    current_hash.should eq("estimate/projects/#{pr.id}")
  end

  scenario 'sort projects', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create :project }
    count = Estimate::Project.all.count
    prs = Estimate::Project.limit(per_page)

    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate.projects.data')
    current_hash.should eq('estimate/projects')
    test_order = lambda do |field, type|
      prs = Estimate::Project.limit(per_page).send("sort_by_#{field}","#{type}")
      wait_for_ajax
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
      check_content("#container_documents table", prs) do |pr|
        [pr.customer.tag, pr.place.tag]
      end
    end

    test_order.call('place_tag','asc')
    test_order.call('place_tag','desc')
    test_order.call('customer_tag','asc')
    test_order.call('customer_tag','desc')
  end
end
