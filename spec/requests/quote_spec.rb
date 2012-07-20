# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

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

    titles = [I18n.t('views.quote.resource'), I18n.t('views.quote.date'),
              I18n.t('views.quote.rate')]

    check_header("#container_documents table", titles)
    check_content("#container_documents table", quote) do |item|
      [item.money.alpha_code, item.day.strftime('%Y-%m-%d'), item.rate.to_i]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")
    quote = Quote.limit(per_page).offset(per_page)
    check_content("#container_documents table", quote) do |item|
      [item.money.alpha_code, item.day.strftime('%Y-%m-%d'), item.rate.to_i]
    end
  end
end
