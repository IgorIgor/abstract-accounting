# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'bo_m', %q{
  As an user
  I want to view bo_m
} do

  before :each do
    create :chart
  end

  scenario 'bom - bom', js: true do
    page_login
    page.find('#btn_slide_estimate').click
    click_link I18n.t('views.home.estimate')
    current_hash.should eq('estimates/bo_ms/new')
    page.should have_content(I18n.t('views.estimates.uid'))
    page.should have_content(I18n.t('views.resources.tag'))
    page.should have_content(I18n.t('views.resources.mu'))
    titles = [I18n.t('views.estimates.code'), I18n.t('views.resources.tag'),
              I18n.t('views.resources.mu'), I18n.t('views.estimates.rate')]
    check_header("#container_documents table", titles)

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")
    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq(nil)
    find_field('asset_mu')[:disabled].should eq(nil)
    find_field('builders')[:disabled].should eq(nil)
    find_field('rank')[:disabled].should eq(nil)
    find_field('machinist')[:disabled].should eq(nil)

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.uid')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.resources.tag')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.resources.mu')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('uid', :with => '123456')
      6.times { create(:asset) }
      resources = Asset.order(:tag).limit(6)
      fill_in('asset_tag', :with => resources[0].tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[3].click
      end
      find_field('asset_mu')[:value].should eq(resources[3].mu)

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}")
      end

      fill_in('builders', :with => '150')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.rank')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('builders', :with => '')
      fill_in('rank', :with => '160')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('builders', :with => '150')



      page.should have_content('3')
      page.should have_content(I18n.t('views.estimates.elements.machinery'))
      page.should have_xpath(".//td/span[@id='add-mach']")
      page.find(:xpath, ".//td/span[@id='add-mach']").click
      page.should have_content(I18n.t('views.estimates.elements.mu.machine'))
      page.should have_xpath(".//td/span[@id='remove-mach']")

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.code')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinery')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.blank')}")
      end

      page.find(:xpath, ".//td/span[@id='remove-mach']").click

      page.should have_content('4')
      page.should have_content(I18n.t('views.estimates.elements.resources'))
      page.should have_xpath(".//td/span[@id='add-res']")
      page.find(:xpath, ".//td/span[@id='add-res']").click
      page.should have_xpath(".//td/span[@id='remove-res']")

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.code')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.resources.mu')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.blank')}")
      end

      fill_in('resources_code_0', :with => '456')
      check_autocomplete('resources_tag_0', resources, :tag, :should_clear)
      fill_in('resources_rate_0', :with => '185')


      fill_in('builders', :with => 'a')
      fill_in('rank', :with => 'b')
      fill_in('machinist', :with => 'c')
      fill_in('resources_rate_0', :with => 'f')

      click_button(I18n.t('views.users.save'))
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.estimates.elements.builders')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.rank')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.machinist')} : #{I18n.t('errors.messages.number')}")
        page.should have_content("#{I18n.t(
            'views.estimates.elements.resources')}#0 #{I18n.t(
            'views.estimates.rate')} : #{I18n.t('errors.messages.number')}")
      end

      fill_in('builders', :with => '150')
      fill_in('rank', :with => '160')
      fill_in('machinist', :with => '')
      fill_in('resources_rate_0', :with => '190')


      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "estimates/bo_ms/#{Estimate::BoM.last.id}"
      Estimate::BoM.last.items.count.should eq(3)
      visit '#inbox'
      visit "#estimates/bo_ms/#{Estimate::BoM.last.id}"
    end

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq('true')
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq('true')
    find_field('asset_tag')[:disabled].should eq('true')
    find_field('asset_mu')[:disabled].should eq('true')
    find_field('builders')[:disabled].should eq('true')
    find_field('rank')[:disabled].should eq('true')
    find_field('resources_code_0')[:disabled].should eq('true')
    find_field('resources_tag_0')[:disabled].should eq('true')
    find_field('resources_mu_0')[:disabled].should eq('true')
    find_field('resources_rate_0')[:disabled].should eq('true')

    within("#container_documents table tbody") do
      page.should_not have_no_content('2')
      page.should_not have_no_content(I18n.t('views.estimates.elements.machinist'))
      page.should_not have_no_content(I18n.t('views.estimates.elements.mu.people'))

      page.should have_no_content('4')
      page.should have_no_content(I18n.t('views.estimates.elements.resources'))
      page.should have_no_xpath(".//td/span[@id='add-res']")
      page.should have_no_xpath(".//td/span[@id='add-mach']")
      page.should have_no_xpath(".//td/span[@id='remove-res']")
      page.should have_no_xpath(".//td/span[@id='remove-mach']")

    end

    bom = Estimate::BoM.last

    find_field('uid')[:value].should eq(bom.uid)
    find_field('asset_tag')[:value].should eq(bom.resource.tag)
    find_field('asset_mu')[:value].should eq(bom.resource.mu)
    find_field('builders')[:value].should eq(bom.builders[0].rate.to_i.to_s)
    find_field('rank')[:value].should eq(bom.rank[0].rate.to_i.to_s)
    find_field('resources_code_0')[:value].should eq(bom.resources[0].uid)
    find_field('resources_tag_0')[:value].should eq(bom.resources[0].resource.tag)
    find_field('resources_mu_0')[:value].should eq(bom.resources[0].resource.mu)
    find_field('resources_rate_0')[:value].should eq(bom.resources[0].rate.to_i.to_s)

    click_button(I18n.t('views.users.edit'))
    wait_for_ajax

    find_button(I18n.t('views.users.save'))[:disabled].should eq(nil)
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.page.title.edit'))
    end

    page.should have_content('1')
    page.should have_content(I18n.t('views.estimates.elements.builders'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('1.1')
    page.should have_content(I18n.t('views.estimates.elements.rank'))

    page.should have_content('2')
    page.should have_content(I18n.t('views.estimates.elements.machinist'))
    page.should have_content(I18n.t('views.estimates.elements.mu.people'))

    page.should have_content('3')
    page.should have_content(I18n.t('views.estimates.elements.machinery'))
    page.should have_xpath(".//td/span[@id='add-mach']")

    page.should have_content('4')
    page.should have_content(I18n.t('views.estimates.elements.resources'))
    page.should have_xpath(".//td/span[@id='add-res']")

    find_field('uid')[:disabled].should eq(nil)
    find_field('asset_tag')[:disabled].should eq(nil)
    find_field('asset_mu')[:disabled].should eq(nil)
    find_field('builders')[:disabled].should eq(nil)
    find_field('rank')[:disabled].should eq(nil)
    find_field('resources_code_0')[:disabled].should eq(nil)
    find_field('resources_tag_0')[:disabled].should eq(nil)
    find_field('resources_mu_0')[:disabled].should eq(nil)
    find_field('resources_rate_0')[:disabled].should eq(nil)

    fill_in('asset_mu', :with => 'asdfg')
    fill_in('builders', :with => '')
    fill_in('rank', :with => '')
    fill_in('machinist', :with => '')
    page.find(:xpath, ".//td/span[@id='remove-res']").click

    click_button(I18n.t('views.users.save'))
    find("#container_notification").visible?.should be_true
    within("#container_notification") do
      page.should have_content("#{I18n.t(
          'views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}")
    end

    fill_in('machinist', :with => '160')
    page.find(:xpath, ".//td/span[@id='add-mach']").click
    fill_in('machinery_code_0', :with => '123')
    6.times { create(:asset, mu: I18n.t('views.estimates.elements.mu.machine')) }
    resources = Asset.order(:tag).where('mu' => I18n.t('views.estimates.elements.mu.machine')).limit(6)
    check_autocomplete('machinery_tag_0', resources, :tag, :should_clear)
    fill_in('machinery_rate_0', :with => '180')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "estimates/bo_ms/#{bom.id}"
    Estimate::BoM.last.items.count.should eq(2)
    visit '#inbox'
    visit "#estimates/bo_ms/#{Estimate::BoM.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.estimates.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq('true')
    find_button(I18n.t('views.users.edit'))[:disabled].should eq(nil)
    find_field('uid')[:disabled].should eq('true')
    find_field('asset_tag')[:disabled].should eq('true')
    find_field('asset_mu')[:disabled].should eq('true')
    find_field('machinist')[:disabled].should eq('true')
    find_field('machinery_code_0')[:disabled].should eq('true')
    find_field('machinery_tag_0')[:disabled].should eq('true')
    find_field('machinery_rate_0')[:disabled].should eq('true')

    within("#container_documents table tbody") do
      page.should_not have_no_content('1')
      page.should_not have_no_content(I18n.t('views.estimates.elements.builders'))
      page.should_not have_no_content(I18n.t('views.estimates.elements.mu.people'))
      page.should_not have_no_content('1.1')
      page.should_not have_no_content(I18n.t('views.estimates.elements.rank'))

      page.should have_no_content('4')
      page.should have_no_content(I18n.t('views.estimates.elements.resources'))
      page.should have_no_xpath(".//td/span[@id='add-res']")
      page.should have_no_xpath(".//td/span[@id='add-mach']")
      page.should have_no_xpath(".//td/span[@id='remove-res']")
      page.should have_no_xpath(".//td/span[@id='remove-mach']")
    end

    bom = Estimate::BoM.last

    find_field('uid')[:value].should eq(bom.uid)
    find_field('asset_tag')[:value].should eq(bom.resource.tag)
    find_field('asset_mu')[:value].should eq(bom.resource.mu)
    find_field('machinist')[:value].should eq(bom.machinist[0].rate.to_i.to_s)
    find_field('machinery_code_0')[:value].should eq(bom.machinery[0].uid)
    find_field('machinery_tag_0')[:value].should eq(bom.machinery[0].resource.tag)
    find_field('machinery_rate_0')[:value].should eq(bom.machinery[0].rate.to_i.to_s)
  end
end
