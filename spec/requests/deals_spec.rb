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
    check_content("#container_documents table", deals) do |deal|
      if deal.take.resource.instance_of? Asset
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}, #{deal.give.resource.mu}",
         "#{deal.take.resource.tag}, #{deal.take.resource.mu}",
         deal.rate]
      elsif deal.take.resource.instance_of? Money
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}",
         "#{money.tag}",
         deal.rate]
      end
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    deals = Deal.limit(per_page).offset(per_page)
    check_content("#container_documents table", deals) do |deal|
      if deal.take.resource.instance_of? Asset
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}, #{deal.give.resource.mu}",
         "#{deal.take.resource.tag}, #{deal.take.resource.mu}",
         deal.rate]
      elsif deal.take.resource.instance_of? Money
        [deal.tag, deal.entity.tag,
         "#{deal.give.resource.tag}",
         "#{money.tag}",
         deal.rate]
      end
    end
  end
end
