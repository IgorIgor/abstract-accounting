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

  before :each do
    create(:chart)
  end

  scenario 'visit transcripts page', js: true, focus: true do
    rub = Chart.first.currency
    aasii = create(:asset)
    share = create(:deal,
                     give: build(:deal_give, resource: aasii),
                     take: build(:deal_take, resource: rub),
                     rate: 10000)
    bank = create(:deal,
                   give: build(:deal_give, resource: rub),
                   take: build(:deal_take, resource: rub),
                   rate: 1)
    per_page = Settings.root.per_page
    facts = []
    (per_page + 1).times do |i|
      f = create(:fact, from: share, to: bank, resource: rub,
                  amount: 10000 + i)
      facts << f
      create(:txn, fact: f)
    end

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.transcripts')
    current_hash.should eq('transcripts')

    page.should have_datepicker("transcript_date_from")
    page.should have_datepicker("transcript_date_to")

    page.datepicker("transcript_date_from").prev_month.day(10)

    date_from = Time.now.months_ago(1).change(day: 10).to_date
    date_to = Date.today

    page.find('#deal_tag').click
    page.should have_selector('#deals_selector')
    within('#deals_selector') do
      within('table tbody') do
        all(:xpath, './/tr//td[1]').each do |td|
          if td.has_content?(share.tag)
            td.click
            break
          end
        end
      end
    end
    page.should have_no_selector('#deals_selector')

    transcript = Transcript.new(share, DateTime.now.change(day: 10, month:
                                                           DateTime.now.prev_month.month),
                                DateTime.now)
    txns = transcript.all
    txns_count = transcript.count

    within("div[@id='container_documents']")  do
      choose('natural_mu')
    end

    within('#container_documents table') do
      within(:xpath, './/thead//tr[1]') do
        page.find(:xpath, './/td[1]').
            should have_content(transcript.start.strftime('%Y-%m-%d'))
        if transcript.opening.nil? ||
            transcript.opening.side != Balance::PASSIVE
          debit_from = 0.0
        else
          debit_from = transcript.opening.amount
        end
        page.find(:xpath, './/td[2]').should have_content(debit_from)
        if transcript.opening.nil? ||
            transcript.opening.side != Balance::ACTIVE
          credit_from = 0.0
        else
          credit_from = transcript.opening.amount
        end
        page.find(:xpath, './/td[3]').should have_content(credit_from)
      end
      within(:xpath, './/thead//tr[2]') do
        page.should have_content(I18n.t('views.transcripts.date'))
        page.should have_content(I18n.t('views.transcripts.account'))
        page.should have_content(I18n.t('views.transcripts.debit'))
        page.should have_content(I18n.t('views.transcripts.credit'))
      end

      within(:xpath, './/tfoot//tr[1]') do
        page.should have_content(I18n.t('views.transcripts.total_circulation'))
        page.find(:xpath, './/td[2]').should have_content(
                                                 transcript.total_debits)
        page.find(:xpath, './/td[3]').should have_content(
                                                 transcript.total_credits)
      end

      within(:xpath, './/tfoot//tr[2]') do
        page.should have_content(I18n.t('views.transcripts.rate_differences'))
        page.find(:xpath, './/td[2]').should have_content('')
        page.find(:xpath, './/td[3]').should have_content('')
      end

      within(:xpath, './/tfoot//tr[3]') do
        page.find(:xpath, './/td[1]').
            should have_content(transcript.stop.strftime('%Y-%m-%d'))
        if transcript.closing.nil? ||
            transcript.closing.side != Balance::PASSIVE
          debit_to = 0.0
        else
          debit_to = transcript.closing.amount
        end
        page.find(:xpath, './/td[2]').should have_content(debit_to)
        if transcript.closing.nil? ||
            transcript.closing.side != Balance::ACTIVE
          credit_to = 0.0
        else
          credit_to = transcript.closing.amount
        end
        page.find(:xpath, './/td[3]').should have_content(credit_to)
      end

      within('tbody') do
        per_page.times do |i|
          page.should have_content(txns[i].fact.day.strftime('%Y-%m-%d'))
          if share.id == txns[i].fact.to.id
            page.find(:xpath, ".//tr[#{i+1}]/td[3]").
                should have_content(txns[i].fact.amount)
            page.should have_content(txns[i].fact.from.tag)
          else
            page.find(:xpath, ".//tr[#{i+1}]/td[4]").
                should have_content(txns[i].fact.amount)
            page.should have_content(txns[i].fact.to.tag)
          end
          page.should have_content(txns[i].fact.amount)
        end
      end
    end

    within("div[@id='container_documents']")  do
      choose('currency_mu')
    end

    within('#container_documents table') do
      within(:xpath, './/thead//tr[1]') do
        if transcript.opening.nil? ||
            transcript.opening.side != Balance::PASSIVE
          debit_from = 0.0
        else
          debit_from = transcript.opening.value
        end
        page.find(:xpath, './/td[2]').should have_content(debit_from)
        if transcript.opening.nil? ||
            transcript.opening.side != Balance::ACTIVE
          credit_from = 0.0
        else
          credit_from = transcript.opening.value
        end
        page.find(:xpath, './/td[3]').should have_content(credit_from)
      end

      within(:xpath, './/tfoot//tr[1]') do
        page.find(:xpath, './/td[2]').should have_content(
                                                 transcript.total_debits_value)
        page.find(:xpath, './/td[3]').should have_content(
                                                 transcript.total_credits_value)
      end

      within(:xpath, './/tfoot//tr[2]') do
        page.find(:xpath, './/td[2]').should have_content(
                                                 transcript.total_debits_diff)
        page.find(:xpath, './/td[3]').should have_content(
                                                 transcript.total_credits_diff)
      end

      within(:xpath, './/tfoot//tr[3]') do
        if transcript.closing.nil? ||
            transcript.closing.side != Balance::PASSIVE
          debit_to = 0.0
        else
          debit_to = transcript.closing.value
        end
        page.find(:xpath, './/td[2]').should have_content(debit_to)
        if transcript.closing.nil? ||
            transcript.closing.side != Balance::ACTIVE
          credit_to = 0.0
        else
          credit_to = transcript.closing.value
        end
        page.find(:xpath, './/td[3]').should have_content(credit_to)
      end

      within('tbody') do
        per_page.times do |i|
          if transcript.deal.id == txns[i].fact.to.id
            page.find(:xpath, ".//tr[#{i+1}]/td[3]").
                should have_content(txns[i].value)
          end
          if transcript.deal.id == txns[i].fact.from.id
            page.find(:xpath, ".//tr[#{i+1}]/td[4]").
                should have_content(txns[i].value)
          end
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
      find_button('>')[:disabled].should be_nil
      click_button('>')
      find_button('<')[:disabled].should be_nil

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
      find_button('>')[:disabled].should be_nil
    end

    within("#container_documents") do
      page.find(:xpath, './/table/tbody/tr[1]/td[1]').click
      if transcript.deal.id == txns[0].fact.from.id
        page.find(:xpath, './/table/tbody/tr[1]/td[2]').
            should have_content(txns[0].fact.from.tag)
        page.find('#deal_tag')[:value].should have_content(txns[0].fact.to.tag)
      else
        page.find(:xpath, './/table/tbody/tr[1]/td[2]').
            should have_content(txns[0].fact.to.tag)
        page.find('#deal_tag')[:value].should have_content(txns[0].fact.from.tag)
      end
      Date.parse(page.find('#transcript_date_from')[:value]).
          should eq(date_from)
      Date.parse(page.find('#transcript_date_to')[:value]).
          should eq(date_to)
    end

    click_link I18n.t('views.home.general_ledger')

    within('#container_documents') do
      page.find(:xpath, './/table/tbody/tr[1]/td[1]').click
    end

    date = facts[0].day.strftime('%Y-%m-%d')
    current_hash.should eq(
      "transcripts?date_from=#{date}&date_to=#{date}&deal_id=#{bank.id}")
    page.find('#deal_tag')[:value].should eq(bank.tag)
    page.find('#transcript_date_from')[:value].
        should eq(facts[0].day.strftime('%d.%m.%Y'))
    page.find('#transcript_date_to')[:value].
        should eq(facts[0].day.strftime('%d.%m.%Y'))

    within('#container_documents table') do
      within(:xpath, './/thead//tr[1]') do
        page.find(:xpath, './/td[1]').
            should have_content(facts[0].day.strftime('%Y-%m-%d'))
      end

      within(:xpath, './/tfoot//tr[3]') do
        page.find(:xpath, './/td[1]').
            should have_content(facts[0].day.strftime('%Y-%m-%d'))
      end

      within('tbody') do
        filtered_txns = txns.all.select { |txn| txn.fact.to == bank }
        per_page.times do |i|
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.day.strftime('%Y-%m-%d'))
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.from.tag)
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.amount)
        end
      end
    end

    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')

    within('#container_documents') do
      page.find(:xpath, './/table/tbody/tr[1]/td[1]/input').click
    end
    click_button(I18n.t 'views.deals.report_on_selected')

    deal = Deal.limit(per_page).first
    date = DateTime.now.strftime('%Y-%m-%d')
    current_hash.should eq(
      "transcripts?deal_id=#{deal.id}&date_from=#{date}&date_to=#{date}")

    page.find('#deal_tag')[:value].should eq(deal.tag)
    page.find('#transcript_date_from')[:value].
        should eq(DateTime.now.strftime('%d.%m.%Y'))
    page.find('#transcript_date_to')[:value].
        should eq(DateTime.now.strftime('%d.%m.%Y'))

    within('#container_documents table') do
      within(:xpath, './/thead//tr[1]') do
        page.find(:xpath, './/td[1]').
            should have_content(DateTime.now.strftime('%Y-%m-%d'))
      end

      within(:xpath, './/tfoot//tr[3]') do
        page.find(:xpath, './/td[1]').
            should have_content(DateTime.now.strftime('%Y-%m-%d'))
      end

      within('tbody') do
        filtered_txns = txns.all.select { |txn| txn.fact.to == bank }
        per_page.times do |i|
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.day.strftime('%Y-%m-%d'))
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.to.tag)
          page.find(:xpath, ".//tr[#{i+1}]").
              should have_content(filtered_txns[i].fact.amount)
        end
      end
    end
  end

  scenario 'sort transcripts', js: true do
    rub = Chart.first.currency
    aasii = create(:asset)
    share = create(:deal,
                   give: build(:deal_give, resource: aasii),
                   take: build(:deal_take, resource: rub),
                   rate: 10000)
    bank = create(:deal,
                  give: build(:deal_give, resource: rub),
                  take: build(:deal_take, resource: rub),
                  rate: 1)
    per_page = Settings.root.per_page
    facts = []
    (per_page + 1).times do |i|
      f = create(:fact, from: share, to: bank, resource: rub,
                 amount: 10000 + i)
      facts << f
      create(:txn, fact: f)
    end

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.transcripts')
    current_hash.should eq('transcripts')

    page.should have_datepicker("transcript_date_from")
    page.should have_datepicker("transcript_date_to")

    page.datepicker("transcript_date_from").prev_month.day(10)

    page.find('#deal_tag').click
    page.should have_selector('#deals_selector')
    within('#deals_selector') do
      within('table tbody') do
        all(:xpath, './/tr//td[1]').each do |td|
          if td.has_content?(share.tag)
            td.click
            break
          end
        end
      end
    end

    transcript = Transcript.new(share,
                                DateTime.now.change(day: 10, month: DateTime.now.prev_month.month),
                                DateTime.now)

    test_order = lambda do |field, type|
      trans = transcript.all(order: {field: field,type: type})
      within('#container_documents table') do
        within('thead tr[2]') do
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
      check_content("#container_documents table", trans) do |txn|
        [txn.fact.day.strftime('%Y-%m-%d'), txn.fact.to.tag || txn.fact.from.tag, txn.fact.amount]
      end
    end

    test_order.call('day', 'asc')
    test_order.call('day', 'desc')
  end
end
