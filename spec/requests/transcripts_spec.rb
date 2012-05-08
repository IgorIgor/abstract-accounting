# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "rspec"
require 'spec_helper'

feature "Transcripts", %q{
  As an user
  I want to view transcripts
} do

  scenario 'visit transcripts page', js: true do
    rub = Factory(:chart).currency
    aasii = Factory(:asset)
    share = Factory(:deal,
                     give: Factory.build(:deal_give, resource: aasii),
                     take: Factory.build(:deal_take, resource: rub),
                     rate: 10000)
    bank = Factory(:deal,
                   give: Factory.build(:deal_give, resource: rub),
                   take: Factory.build(:deal_take, resource: rub),
                   rate: 1)
    per_page = Settings.root.per_page
    facts = []
    (per_page + 1).times do |i|
      f = Factory(:fact, from: share, to: bank, resource: rub,
                  amount: 10000 + i)
      facts << f
      Factory(:txn, fact: f)
    end

    page_login
    click_link I18n.t('views.home.transcripts')
    current_hash.should eq('transcripts')
    page.should have_xpath("//li[@id='transcripts' and @class='sidebar-selected']")

    page.should have_datepicker("transcript_date_from")
    page.should have_datepicker("transcript_date_to")

    page.datepicker("transcript_date_from").prev_month.day(1)

    5.times { Factory(:deal) }
    items = Deal.limit(6).all.sort
    check_autocomplete("deal_tag", items, :tag)
    fill_in('deal_tag', with: share.tag)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
        " and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end

    transcript = Transcript.new(share, DateTime.now.change(day: 1, month: DateTime.now.month),
                                DateTime.now + 1)
    txns = transcript.all
    txns_count = transcript.count

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.transcripts.date'))
        page.should have_content(I18n.t('views.transcripts.account'))
        page.should have_content(I18n.t('views.transcripts.debit'))
        page.should have_content(I18n.t('views.transcripts.credit'))
      end

      within('tbody') do
        per_page.times do |i|
          page.should have_content(txns[i].fact.day.strftime('%Y-%m-%d'))
          if share.id == txns[i].fact.to.id
            page.should have_content(txns[i].fact.from.tag)
          else
            page.should have_content(txns[i].fact.to.tag)
          end
          page.should have_content(txns[i].fact.amount)
        end
      end
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    to_range = (txns_count > per_page * 2) ? per_page * 2 : txns_count

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find("span[@data-bind='text: count']").
          should have_content(txns_count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
      click_button('>')
      find_button('<')[:disabled].should eq('false')

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: to_range - per_page)
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
