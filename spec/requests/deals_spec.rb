# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

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
              I18n.t('views.deals.give'), I18n.t('views.deals.take'),
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
      page.find(:xpath, ".//tr[2]").visible?.should_not be_true
      page.find(:xpath, ".//tr[1]//td[@class='tree-actions']").click
      page.find(:xpath, ".//tr[2]//td[@class='td-inner-table']").visible?.should be_true
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
      page.find("#rules_#{deal_1.id}").visible?.should_not be_true
      page.find("#rules_#{deal_2.id}").visible?.should_not be_true
      page.find(:xpath, ".//tr[3]//td[@class='tree-actions']").click
      page.find("#rules_#{deal_2.id}").visible?.should_not be_true
    end
  end
end
