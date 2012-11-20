# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

def check_components_enable(readonly)
  readonly_str = readonly ? "true" : nil
  no_readonly_str = (!readonly) ? "true" : nil

  find_button(I18n.t('views.users.save'))[:disabled].should eq(readonly_str)
  find_button(I18n.t('views.users.edit'))[:disabled].should eq(no_readonly_str)
  find_field('deal_tag')[:disabled].should eq(readonly_str)
  find_field('deal_entity')[:disabled].should eq(readonly_str)
  find('#is_off_balance')[:disabled].should eq(readonly_str)
  find_field('deal_rate')[:disabled].should eq(readonly_str)
  find_field('deal_give_resource')[:disabled].should eq(readonly_str)
  find_field('deal_give_place')[:disabled].should eq(readonly_str)
  find_field('deal_take_resource')[:disabled].should eq(readonly_str)
  find_field('deal_take_place')[:disabled].should eq(readonly_str)
  find_button(I18n.t('views.users.add'))[:disabled].should eq(readonly_str)
  find_field('rule_from_tag_0')[:disabled].should eq(readonly_str)
  find_field('rule_to_tag_0')[:disabled].should eq(readonly_str)
  find_field('rule_rate_0')[:disabled].should eq(readonly_str)
  find('#fact_side_0')[:disabled].should eq(readonly_str)
  find('#change_side_0')[:disabled].should eq(readonly_str)
end

feature 'deals', %q{
  As an user
  I want to view deals
} do

  before :each do
    create(:chart)
  end

  scenario 'view deals', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:deal) }
    deals = Deal.limit(per_page)
    deals[0].give.resource.update_attributes!(mu: nil)
    money = create(:money)
    deals[0].take.resource = money
    deals[0].take.save!

    count = Deal.count
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
      "/div[@class='slide_action']" +
      "/a[@id='deals' and @class='btn_slide_action sidebar-selected']")

    titles = [I18n.t('views.deals.tag'), I18n.t('views.deals.entity'),
              I18n.t('views.deals.give.tag'), I18n.t('views.deals.take.tag'),
              I18n.t('views.deals.rate')]

    check_header("#container_documents table", titles)
    check_group_content("#container_documents table", deals) do |deal|
      if deal.take.resource.instance_of? Asset
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}, #{deal.give.resource.mu}",
         "#{deal.take.resource.tag}, #{deal.take.resource.mu}",
         deal.rate]
      elsif deal.take.resource.instance_of? Money
        [deal.tag, deal.entity.tag, "#{deal.give.resource.tag}", "#{money.tag}", deal.rate]
      end
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    deals = Deal.limit(per_page).offset(per_page)
    check_group_content("#container_documents table", deals) do |deal|
      if deal.take.resource.instance_of? Asset
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}, #{deal.give.resource.mu}",
         "#{deal.take.resource.tag}, #{deal.take.resource.mu}",
         deal.rate]
      elsif deal.take.resource.instance_of? Money
        [deal.tag, deal.entity.tag, "#{deal.give.resource.tag}", "#{money.tag}", deal.rate]
      end
    end
  end

  scenario 'view rules', js: true do
    per_page = Settings.root.per_page
    deal_1 = create(:deal)
    deal_2 = create(:deal)
    count = per_page + 1
    (per_page + 1).times {create(:rule, deal: deal_1)}
    rules = Rule.limit(per_page)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/div[@class='slide_action']" +
                           "/a[@id='deals' and @class='btn_slide_action sidebar-selected']")

    within("#container_documents table tbody") do
      within(:xpath, ".//tr[1]//td[@class='tree-actions']") do
        page.should have_selector("div[@class='ui-corner-all ui-state-hover']")
      end
      within(:xpath, ".//tr[3]//td[@class='tree-actions']") do
        page.should have_selector("div[@class='ui-corner-all ui-state-default']")
      end
      page.should_not have_xpath(".//tr[2]")
      page.find(:xpath, ".//tr[1]//td[@class='tree-actions']").click
      page.should_not have_xpath(".//tr[2]//td[@class='td-inner-table']")
    end

    titles = [I18n.t('views.rules.tag'), I18n.t('views.rules.resource'),
              I18n.t('views.rules.from'), I18n.t('views.rules.to'),
              I18n.t('views.rules.rate')]
    check_header("#rules_#{deal_1.id} table[@class='inner-table']", titles)

    check_content("#rules_#{deal_1.id} table[@class='inner-table']", rules) do |rule|
      [rule.tag, rule.rate.to_i, rule.from.take.resource.tag, rule.from.tag, rule.to.tag]
    end
    check_paginate("#rules_#{deal_1.id} div[@class='paginate']", count, per_page)
    next_page("#rules_#{deal_1.id} div[@class='paginate']")

    rules = Rule.limit(per_page).offset(per_page)
    check_content("#rules_#{deal_1.id} table[@class='inner-table']", rules) do |rule|
      [rule.tag, rule.rate.to_i, rule.from.take.resource.tag, rule.from.tag, rule.to.tag]
    end

    within("#container_documents table tbody") do
      page.find(:xpath, ".//tr[1]//td[@class='tree-actions']").click
      page.should_not have_selector("#rules_#{deal_1.id}")
      page.should_not have_selector("#rules_#{deal_2.id}")
      page.find(:xpath, ".//tr[3]//td[@class='tree-actions']").click
      page.should_not have_selector("#rules_#{deal_2.id}")
    end
  end

  scenario 'create/edit deal', js: true do
    page_login
    page.find('#btn_slide_services').click
    click_link I18n.t('views.home.deal')
    current_hash.should eq('documents/deals/new')
    page.should have_xpath("//li[@id='deals_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.deals.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.deals.tag')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.entity')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.rate')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.give.resource')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.take.resource')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.give.place')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.take.place')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('deal_tag', with: 'new deal')
    6.times { create(:legal_entity) }
    entities = LegalEntity.order(:name).limit(6)
    check_autocomplete('deal_entity', entities, :name, :should_clear)
    fill_in('deal_rate', with: '2')
    6.times { create(:asset) }
    resources = Asset.order(:tag).limit(6)
    check_autocomplete('deal_give_resource', resources, :tag, :should_clear)
    6.times { create(:place) }
    places = Place.order(:tag).limit(6)
    check_autocomplete('deal_give_place', places, :tag, :should_clear)
    fill_in('deal_take_resource', :with => resources[0].tag[0..1])
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[3].click
    end
    fill_in('deal_take_place', :with => places[0].tag[0..1])
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[3].click
    end
    find('input#period')[:disabled].should be_true
    page.should have_datepicker("execution_date")
    page.datepicker("execution_date").next_month.day(11)
    find('input#period')[:disabled].should be_false
    find("#container_notification").visible?.should be_true
      page.should have_content("#{I18n.t(
          'views.deals.compensation_period')} : #{I18n.t('errors.messages.blank')}")
    fill_in('period', :with => 5.1)
    find("#container_notification").visible?.should be_true
      page.should have_content("#{I18n.t(
          'views.deals.compensation_period')} : #{I18n.t('errors.messages.digits')}")

    fill_in('period', :with => 5)

    page.should_not have_selector("#container_notification")

    click_button(I18n.t('views.users.add'))
    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.deals.rules')}#0 #{I18n.t('views.rules.from')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.deals.rules')}#0 #{I18n.t('views.rules.to')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    d1 = create(:deal)
    d2 = create(:deal)
    d3 = create(:deal)

    fill_in('rule_from_tag_0', :with => d1.tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('rule_to_tag_0', :with => d2.tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('rule_rate_0', :with => '2')

    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/deals/#{Deal.last.id}"
    end.should change(Deal, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.deals.page.title.show'))
    end

    check_components_enable(true)

    find_field('deal_tag')[:value].should eq('new deal')
    find_field('deal_entity')[:value].should eq(entities[1].name)
    find('#is_off_balance')[:checked].should_not eq('true')
    find_field('deal_rate')[:value].should eq('2')
    find_field('deal_give_resource')[:value].should eq(resources[1].tag)
    find_field('deal_give_place')[:value].should eq(places[1].tag)
    find_field('deal_take_resource')[:value].should eq(resources[3].tag)
    find_field('deal_take_place')[:value].should eq(places[3].tag)
    find_field('execution_date')[:value].should eq(Deal.last.execution_date.strftime('%d.%m.%Y'))
    find_field('period')[:value].should eq(Deal.last.compensation_period.to_s)
    find_field('rule_from_tag_0')[:value].should eq(d1.tag)
    find_field('rule_to_tag_0')[:value].should eq(d2.tag)
    find_field('rule_rate_0')[:value].should eq('2')
    find('#fact_side_0')[:checked].should_not eq('true')
    find('#change_side_0')[:checked].should_not eq('true')

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/deals/#{Deal.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.deals.page.title.edit'))
    end

    check_components_enable(false)

    fill_in('deal_tag', with: 'new edited deal')
    fill_in('deal_entity', :with => entities[0].name[0..1])
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[2].click
    end
    check('is_off_balance')
    fill_in('deal_give_resource', :with => resources[0].tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('execution_date', :with => '')
    fill_in('deal_give_place', :with => places[0].tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('rule_from_tag_0', :with => d3.tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    check('fact_side_0')
    check('change_side_0')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/deals/#{Deal.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.deals.page.title.show'))
    end

    check_components_enable(true)

    find_field('deal_tag')[:value].should eq('new edited deal')
    find_field('deal_entity')[:value].should eq(entities[2].name)
    find('#is_off_balance')[:checked].should eq('true')
    find_field('deal_give_resource')[:value].should eq(resources[0].tag)
    find_field('deal_give_place')[:value].should eq(places[0].tag)
    find_field('rule_from_tag_0')[:value].should eq(d3.tag)
    find('#fact_side_0')[:checked].should eq('true')
    find('#change_side_0')[:checked].should eq('true')

    deal = Deal.last
    rub = create(:chart).currency
    deal_from = create(:deal,
                       :give => build(:deal_give, resource: rub),
                       :take => deal.give,
                       :rate => 10.0)
    create(:fact, from: deal_from, to: deal, resource: deal.give.resource)

    visit "/#documents/deals/#{Deal.last.id}"
    find_button(I18n.t('views.users.save'))[:disabled].should be_true
    find_button(I18n.t('views.users.edit'))[:disabled].should be_true
  end

  scenario 'sort deals', js: true do
    10.times { create(:deal) }

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                               "/div[@class='slide_action']" +
                               "/a[@id='deals' and " +
                               "@class='btn_slide_action sidebar-selected']")

    test_order = lambda do |field, type|
      deals = Deal.sort(field, type)
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
      check_group_content("#container_documents table", deals) do |deal|
        if deal.take.resource.instance_of? Asset
          [deal.tag, deal.entity.tag,
           "#{deal.give.resource.tag}, #{deal.give.resource.mu}",
           "#{deal.take.resource.tag}, #{deal.take.resource.mu}",
           deal.rate]
        elsif deal.take.resource.instance_of? Money
          [deal.tag, deal.entity.tag, "#{deal.give.resource.tag}", "#{money.tag}", deal.rate]
        end
      end
    end

    test_order.call('tag','asc')
    test_order.call('tag','desc')

    test_order.call('name','asc')
    test_order.call('name','desc')

    test_order.call('give','asc')
    test_order.call('give','desc')

    test_order.call('take','asc')
    test_order.call('take','desc')

    test_order.call('rate','asc')
    test_order.call('rate','desc')
  end
end
