# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

def should_present_quote(quote)
  page.should have_content(quote.money.alpha_code)
  page.should have_content(quote.day.strftime('%Y-%m-%d'))
  page.should have_content(quote.rate.to_i)
end

feature 'quote', %q{
  As an user
  I want to view quote
} do

  before :each do
    create(:chart)
  end

  scenario 'view quote', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:quote, money: create(:money)) }
    quote = Quote.limit(per_page).all
    count = Quote.count
    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.quote')
    current_hash.should eq('quote')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/li[@id='quote' and @class='sidebar-selected']")

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.quote.resource'))
        page.should have_content(I18n.t('views.quote.date'))
        page.should have_content(I18n.t('views.quote.rate'))
      end

      within('tbody') do
        page.should have_selector('tr', count: per_page)
        quote.each_with_index do |q, i|
          within(:xpath, ".//tr[#{i + 1}]") do
            should_present_quote(q)
          end
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

    within("div[@class='paginate']") do
      click_button('>')

      to_range = count > (per_page * 2) ? per_page * 2 : count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(count.to_s)

      find_button('<')[:disabled].should eq('false')
    end

    quote = Quote.limit(per_page).offset(per_page)
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page

      page.should have_selector('tr', count: count_on_page)
      quote.each_with_index do |q, i|
        within(:xpath, ".//tr[#{i + 1}]") do
          should_present_quote(q)
        end
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
