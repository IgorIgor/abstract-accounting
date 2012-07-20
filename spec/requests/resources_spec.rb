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

    resources = Resource.all(page: 1, per_page: per_page)
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


    resources = Resource.all(page: 2, per_page: per_page)

    check_content("#container_documents table", resources) do |res|
      [res.tag, res.ext_info, I18n.t("activerecord.models.#{res.type.tableize.singularize}")]
    end
  end

  scenario 'view balances by asset', js: true do
    res = create(:asset)
    res2 = create(:asset)
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
      page.find(:xpath, ".//tr[1]/td[1]").click
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
end
