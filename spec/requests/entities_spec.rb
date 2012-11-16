# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'entities', %q{
  As an user
  I want to view entities
} do

  before :each do
    create(:chart)
  end

  scenario 'view entities', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:entity) }
    create(:legal_entity)

    entities = SubjectOfLaw.paginate(page: 1, per_page: per_page).all
    count = SubjectOfLaw.count

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/li[@id='entities' and @class='sidebar-selected']")

    titles = [I18n.t('views.entities.tag'), I18n.t('views.entities.type')]

    check_header("#container_documents table", titles)
    check_content("#container_documents table", entities) do |entity|
      [entity.tag, I18n.t("activerecord.models.#{entity.type.tableize.singularize}")]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")

    entities = SubjectOfLaw.paginate(page: 2, per_page: per_page).all

    check_content("#container_documents table", entities) do |entity|
      [entity.tag, I18n.t("activerecord.models.#{entity.type.tableize.singularize}")]
    end
  end

  scenario 'view balances by entity', js: true do
    entity = create(:legal_entity)
    deal = create(:deal, entity: entity, rate: 10)
    create(:balance, deal: deal)
    entity2 = create(:entity)
    deal2 = create(:deal, entity: entity2, rate: 10)
    create(:balance, deal: deal2)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                           "//li[@id='entities' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[1]/input").click
      page.find(:xpath, ".//tr[2]/td[1]/input").click
    end
    find("#report_on_selected").click
    current_hash.should eq("balance_sheet?entities%5B0%5D%5Bid%5D=#{entity2.id}&"+
                                   "entities%5B0%5D%5Btype%5D=#{entity2.class.name}&"+
                                    "entities%5B1%5D%5Bid%5D=#{entity.id}&"+
                                  "entities%5B1%5D%5Btype%5D=#{entity.class.name}")
    find('#slide_menu_conditions').visible?.should be_true
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 2)
      page.should have_content(deal.tag)
      page.should have_content(deal.entity.name)
      page.should have_content(deal2.tag)
      page.should have_content(deal2.entity.name)
    end
  end

  scenario 'show entity', js: true do
    entity = create(:entity)
    deal = create(:deal, entity: entity, rate: 10)
    create(:balance, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='entities' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[2]").click
    end
    current_hash.should eq("documents/entities/#{entity.id}")
  end

  scenario 'show legal_entity', js: true do
    entity = create(:legal_entity)
    deal = create(:deal, entity: entity, rate: 10)
    create(:balance, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='entities' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[2]").click
    end
    current_hash.should eq("documents/legal_entities/#{entity.id}")
  end

  scenario 'create/edit entity', js: true do
    page_login
    page.find('#btn_slide_services').click
    page.find('#arrow_entities_actions').click
    click_link I18n.t('views.home.entity')
    current_hash.should eq('documents/entities/new')
    page.should have_xpath("//li[@id='entities_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.entities.tag')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('entity_tag', with: 'new entity')
    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/entities/#{Entity.last.id}"
    end.should change(Entity, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('entity_tag')[:disabled].should eq("true")
    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/entities/#{Entity.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.edit'))
    end

    find_field('entity_tag')[:disabled].should be_nil

    fill_in('entity_tag', with: 'edited new entity')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/entities/#{Entity.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('entity_tag')[:disabled].should eq("true")
    find_field('entity_tag')[:value].should eq('edited new entity')
  end

  scenario 'create/edit legal entity', js: true do
    page_login
    page.find('#btn_slide_services').click
    page.find('#arrow_entities_actions').click
    click_link I18n.t('views.home.legal_entity')
    current_hash.should eq('documents/legal_entities/new')
    page.should have_xpath("//li[@id='legal_entities_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.legal_entities.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.legal_entities.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.legal_entities.country')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.legal_entities.ident_value')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('legal_entity_name', with: 'new legal entity')
    6.times { create(:country) }
    items = Country.order(:tag).limit(6)
    check_autocomplete('legal_entity_country', items, :tag, :should_clear)
    fill_in('legal_entity_ident_value', with: '33')

    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/legal_entities/#{LegalEntity.last.id}"
    end.should change(LegalEntity, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.legal_entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq('true')
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('legal_entity_name')[:disabled].should eq('true')
    find_field('legal_entity_country')[:disabled].should eq('true')
    find('#legal_entity_ident_name')[:disabled].should eq('true')
    find_field('legal_entity_ident_value')[:disabled].should eq('true')

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/legal_entities/#{LegalEntity.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.legal_entities.page.title.edit'))
    end

    find_field('legal_entity_name')[:disabled].should be_nil
    find_field('legal_entity_country')[:disabled].should be_nil
    find('#legal_entity_ident_name')[:disabled].should be_nil
    find_field('legal_entity_ident_value')[:disabled].should be_nil

    fill_in('legal_entity_name', with: 'new edited legal entity')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/legal_entities/#{LegalEntity.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.legal_entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('legal_entity_name')[:disabled].should eq("true")
    find_field('legal_entity_name')[:value].should eq('new edited legal entity')
  end

  scenario 'sort entity\legal_entity', js: true do
    create(:entity)
    create(:legal_entity)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                               "//li[@id='entities' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
      entities = SubjectOfLaw.sort(field, type)
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
      check_content("#container_documents table", entities.all) do |entity|
        [entity.tag, I18n.t("activerecord.models.#{entity.type.tableize.singularize}")]
      end
    end

    test_order.call('tag','asc')
    test_order.call('tag','desc')

    test_order.call('type','asc')
    test_order.call('type','desc')
  end
end
