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

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.deals.tag'))
        page.should have_content(I18n.t('views.deals.entity'))
        page.should have_content(I18n.t('views.deals.give'))
        page.should have_content(I18n.t('views.deals.take'))
        page.should have_content(I18n.t('views.deals.rate'))
      end

      within('tbody') do
        find(:xpath, ".//tr[1]/td[3]").
            should have_content(deals[0].give.resource.tag)
        find(:xpath, ".//tr[1]/td[4]").
            should have_content(money.tag)

        (1..per_page-1).each do |i|
          page.should have_content(deals[i].tag)
          page.should have_content(deals[i].entity.tag)
          page.should have_content("#{deals[i].give.resource.tag}, #{
                                      deals[i].give.resource.mu}")
          page.should have_content("#{deals[i].take.resource.tag}, #{
                                      deals[i].take.resource.mu}")
          page.should have_content(deals[i].rate)
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

    deals = Deal.limit(per_page).offset(per_page)
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page
      page.should have_selector('tr', count: count_on_page)
      deals.each do |deal|
        page.should have_content(deal.tag)
        page.should have_content(deal.entity.tag)
        page.should have_content("#{deal.give.resource.tag}, #{deal.give.resource.mu}")
        page.should have_content("#{deal.take.resource.tag}, #{deal.take.resource.mu}")
        page.should have_content(deal.rate)
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
end
