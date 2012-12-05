# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'fact', %q{
  As an user
  I want to view fact
} do

  before :each do
    create(:chart)
  end

  scenario 'create/view fact', js: true do
    roof = create(:asset)
    brick = create(:asset)
    share1 = create(:deal,
                    :give => build(:deal_give, :resource => roof),
                    :take => build(:deal_take, :resource => roof),
                    :rate => 1.0,
                    :tag => 'share_deal1')
    share1.limit.update_attributes(side: Limit::ACTIVE)
    share2 = create(:deal,
                    :give => build(:deal_give, :resource => roof),
                    :take => build(:deal_take, :resource => roof),
                    :rate => 1.0,
                    :tag => 'share_deal2')
    other_deal = create(:deal,
                        :give => build(:deal_give, :resource => brick),
                        :take => build(:deal_take, :resource => brick),
                        :rate => 1.0,
                        :tag => 'other_deal')

    page_login
    page.find('#btn_slide_services').click
    click_link I18n.t('views.home.fact')
    current_hash.should eq('documents/facts/new')
    page.should have_xpath("//li[@id='facts_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.facts.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.facts.day')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.facts.from')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.facts.to')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.facts.amount')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.should have_datepicker('fact_day')
    page.datepicker('fact_day').day(Date.today.day)

    find('#fact_from_deal').click
    page.should have_selector('#deals_selector')
    within('#deals_selector') do
      within('table tbody') do
        all(:xpath, './/tr//td[1]').each do |td|
          if td.has_content?(share1.tag)
            td.click
            break
          end
        end
      end
    end
    page.should have_no_selector('#deals_selector')

    find('#fact_to_deal').click
    page.should have_selector('#deals_selector')
    within('#deals_selector') do
      within('table tbody') do
        all(:xpath, './/tr//td[1]').each do |td|
          if td.has_content?(other_deal.tag)
            td.click
            break
          end
        end
      end
    end
    page.should have_no_selector('#deals_selector')

    fill_in('fact_amount', :with => '1')

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content(I18n.t('activerecord.errors.models.fact.bad_resource'))
      end
    end

    find('#fact_to_deal').click
    page.should have_selector('#deals_selector')
    within('#deals_selector') do
      within('table tbody') do
        all(:xpath, './/tr//td[1]').each do |td|
          if td.has_content?(share2.tag)
            td.click
            break
          end
        end
      end
    end
    page.should have_no_selector('#deals_selector')

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until { Fact.count == 1 }
      wait_until_hash_changed_to "documents/facts/#{Fact.last.id}"
    end.should change(Fact, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.facts.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_field('fact_day')[:disabled].should eq("true")
    find_field('fact_from_deal')[:disabled].should eq("true")
    find_field('fact_to_deal')[:disabled].should eq("true")
    find_field('fact_amount')[:disabled].should eq("true")

    fact = Fact.last
    find_field('fact_day')[:value].should eq(fact.day.strftime('%d.%m.%Y'))
    find_field('fact_from_deal')[:value].should eq('share_deal1')
    find_field('fact_to_deal')[:value].should eq('share_deal2')
    find_field('fact_amount')[:value].should eq('1')
  end
end
