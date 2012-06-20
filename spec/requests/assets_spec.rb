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
    assets = Asset.limit(per_page)
    count = Asset.count
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.assets')
    current_hash.should eq('assets')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                            "//li[@id='assets' and @class='sidebar-selected']")

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.assets.tag'))
        page.should have_content(I18n.t('views.assets.mu'))
      end

      within('tbody') do
        assets.each do |asset|
          page.should have_content(asset.tag)
          page.should have_content(asset.mu)
        end
      end
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find("span[@data-bind='text: count']").
          should have_content(count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    within("div[@class='paginate']") do
      click_button('>')

      to_range = count > (per_page * 2) ? per_page * 2 : count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(count.to_s)

      find_button('<')[:disabled].should eq('false')
    end

    assets = Asset.limit(per_page).offset(per_page)
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page
      page.should have_selector('tr', count: count_on_page)
      assets.each do |asset|
        page.should have_content(asset.tag)
        page.should have_content(asset.mu)
      end
    end

    within("div[@class='paginate']") do
      click_button('<')

      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end
  end

  scenario 'view balances by asset', js: true do
    res = create(:asset)
    res2 = create(:asset)
    deal = create(:deal,
                   give: build(:deal_give, resource: res),
                   take: build(:deal_take, resource: res2),
                   rate: 10)
    create(:balance, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.assets')
    current_hash.should eq('assets')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                           "//li[@id='assets' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[1]").click
    end
    current_hash.should eq("balance_sheet?resource_id=#{res.id}")
    find('#slide_menu_conditions').visible?.should be_true
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      page.should have_content(deal.tag)
      page.should have_content(deal.entity.name)
      page.should have_content(res.tag)
    end
  end
end
