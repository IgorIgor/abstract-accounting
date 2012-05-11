# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "single page application", %q{
  As an user
  I want to work with single page
} do

  before do
    PaperTrail.enabled = true
    create(:chart)
    @waybills = []
    @distributions = []
    @per_page = Settings.root.per_page
    (0..(@per_page/2).floor).each do
      wb = build(:waybill)
      wb.add_item('roof', 'm2', 2, 10.0)
      wb.save!
      @waybills << wb

      ds = build(:distribution, storekeeper: wb.storekeeper,
                                        storekeeper_place: wb.storekeeper_place)
      ds.add_item('roof', 'm2', 1)
      ds.save!
      @distributions << ds
    end
  end

  after { PaperTrail.enabled = false }

  scenario 'visit home page', js: true do
    page_login
    visit home_index_path
    current_path.should eq(home_index_path)
    page.should have_content("root@localhost")
    click_link I18n.t('views.home.logout')

    user = create(:user, :password => "somepass")
    page_login(user.email, "somepass")
    page.should have_content(user.entity.tag)
    page.should have_content(I18n.t 'views.home.logout')
    page.should have_content(I18n.t 'views.home.inbox')
    page.should have_content(I18n.t 'views.home.starred')
    page.should have_content(I18n.t 'views.home.drafts')
    page.should have_content(I18n.t 'views.home.sent')
    page.should have_content(I18n.t 'views.home.trash')
    page.should have_content(I18n.t 'views.home.archive')

    current_hash.should eq("inbox")
    page.should have_selector("div[@id='container_documents'] table")
    page.find_by_id("inbox")[:class].should eq("sidebar-selected")

    page.should have_selector("div[@class='button_drop_down_list']")
    page.should have_selector("a[@id='btn_create']")
    page.should_not have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.should_not have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")
    page.find("#btn_create").click
    page.find("#container_documents").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    versions = VersionEx.lasts.by_type([ Waybill.name, Distribution.name ]).
      paginate(page: 1, per_page: @per_page).
      all(include: [item: [:versions, :storekeeper]])

    within('#container_documents table tbody') do
      versions.each do |version|
        page.should have_content(version.item.class.name)
        page.should have_content(version.item.storekeeper.tag)
        page.should have_content(version.item.versions.first.created_at.
                                     strftime('%Y-%m-%d'))
        page.should have_content(version.item.versions.last.created_at.
                                     strftime('%Y-%m-%d'))
      end
    end

    items_count = @waybills.count + @distributions.count

    page.all("div[@class='paginate']").each do |control|
      within("span[@data-bind='text: range']") do
        control.should have_content("1-#{@per_page}")
      end

      within("span[@data-bind='text: count']") do
        control.should have_content(items_count)
      end

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: @per_page)
    end

    click_button('>')

    versions = VersionEx.lasts.by_type([ Waybill.name, Distribution.name ]).
      paginate(page: 2, per_page: @per_page).
      all(include: [item: [:versions, :storekeeper]])

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: items_count / @per_page >= 2 ?
        @per_page : items_count - @per_page)

      versions.each do |version|
        page.should have_content(version.item.class.name)
        page.should have_content(version.item.storekeeper.tag)
        page.should have_content(version.item.versions.first.created_at.
                                   strftime('%Y-%m-%d'))
        page.should have_content(version.item.versions.last.created_at.
                                   strftime('%Y-%m-%d'))
      end
    end

    page.all("div[@class='paginate']").each do |control|
      within("span[@data-bind='text: range']") do
        control.should have_content("#{@per_page+1}-#{
          items_count / @per_page >= 2 ? 2 * @per_page : items_count}")
      end

      within("span[@data-bind='text: count']") do
        control.should have_content(items_count)
      end

      find_button('<')[:disabled].should eq('false')
      if items_count / @per_page > 2
        find_button('>')[:disabled].should eq('false')
      else
        find_button('>')[:disabled].should eq('true')
      end
    end

    page.find("#show-filter").click

    within('#filter-area') do
      page.should have_content(I18n.t('views.waybills.created_at'))
      page.should have_content(I18n.t('views.waybills.document_id'))
      page.should have_content(I18n.t('views.waybills.distributor'))
      page.should have_content(I18n.t('views.waybills.ident_name'))
      page.should have_content(I18n.t('views.waybills.ident_value'))
      page.should have_content(I18n.t('views.waybills.distributor_place'))
      page.should have_content(I18n.t('views.waybills.storekeeper'))
      page.should have_content(I18n.t('views.waybills.storekeeper_place'))

      fill_in('filter-w-created', with: '2')
      fill_in('filter-w-document', with: @waybills[0].document_id)
      fill_in('filter-w-distributor', with: @waybills[0].distributor.name)
      select(I18n.t('views.waybills.ident_name_' +
        @waybills[0].distributor.identifier_name), from: 'filter-w-ident-name')
      fill_in('filter-w-ident-value', with: @waybills[0].distributor.
                                              identifier_value)
      fill_in('filter-w-distributor-place', with: @waybills[0].
                                                    distributor_place.tag)
      fill_in('filter-w-storekeeper', with: @waybills[0].storekeeper.tag)
      fill_in('filter-w-storekeeper-place', with: @waybills[0].
                                                    storekeeper_place.tag)

      click_button(I18n.t('views.home.search'))
    end

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      page.should have_content(@waybills[0].class.name)
      page.should have_content(@waybills[0].storekeeper.tag)
      page.should have_content(@waybills[0].versions.first.created_at.
                                 strftime('%Y-%m-%d'))
      page.should have_content(@waybills[0].versions.last.created_at.
                                 strftime('%Y-%m-%d'))
    end

    page.find("#show-filter").click

    within('#filter-area') do
      page.find(:xpath, "//div[@class='tabs']//ul//li//a[contains(.//text(),
            '#{I18n.t('views.home.distribution')}')]").click

      page.should have_content(I18n.t('views.distributions.created_at'))
      page.should have_content(I18n.t('views.distributions.state'))
      page.should have_content(I18n.t('views.distributions.storekeeper'))
      page.should have_content(I18n.t('views.distributions.storekeeper_place'))
      page.should have_content(I18n.t('views.distributions.foreman'))
      page.should have_content(I18n.t('views.distributions.foreman_place'))

      fill_in('filter-d-created', with: '2')
      select(I18n.t('views.distributions.inwork'), from: 'filter-d-state')

      fill_in('filter-d-storekeeper', with: @distributions[0].storekeeper.tag)
      fill_in('filter-d-storekeeper-place', with: @distributions[0].
                                                    storekeeper_place.tag)
      fill_in('filter-d-foreman', with: @distributions[0].foreman.tag)
      fill_in('filter-d-foreman-place', with: @distributions[0].
                                                foreman_place.tag)

      click_button(I18n.t('views.home.search'))
    end

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 2)
      page.should have_content(@distributions[0].class.name)
      page.should have_content(@distributions[0].storekeeper.tag)
      page.should have_content(@distributions[0].versions.first.created_at.
                                 strftime('%Y-%m-%d'))
      page.should have_content(@distributions[0].versions.last.created_at.
                                 strftime('%Y-%m-%d'))
    end
  end
end
