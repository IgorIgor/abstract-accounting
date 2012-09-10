# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

def show_waybill(waybill)
  current_hash.should eq("documents/waybills/" + waybill.id.to_s)

  page.should have_selector("span[@id='page-title']")
  within('#page-title') do
    page.should have_content("#{I18n.t('views.waybills.page_title_show')}")
  end

  within("#container_documents form") do
    find("#created")[:value].should eq(waybill.created.strftime("%d.%m.%Y"))
    find("#waybill_document_id")[:value].should eq(waybill.document_id)
    find("#waybill_entity")[:value].should eq(waybill.distributor.name)
    find("#waybill_ident_name")[:value].should eq(waybill.distributor.identifier_name)
    find("#waybill_ident_value")[:value].should eq(waybill.distributor.identifier_value)
    find("#distributor_place")[:value].should eq(waybill.distributor_place.tag)
    find("#warehouses")[:value].should eq(waybill.warehouse_id.to_s)

    find("#created")[:disabled].should eq("true")
    find("#waybill_document_id")[:disabled].should eq("true")
    find("#waybill_entity")[:disabled].should eq("true")
    find("#waybill_ident_name")[:disabled].should eq("true")
    find("#waybill_ident_value")[:disabled].should eq("true")
    find("#distributor_place")[:disabled].should eq("true")
    find("#warehouses")[:disabled].should eq("true")

    within("table tbody") do
      waybill.items.each_with_index do |item, idx|
        find("#tag_#{idx}")[:value].should eq(item.resource.tag)
        find("#mu_#{idx}")[:value].should eq(item.resource.mu)
        find("#count_#{idx}")[:value].to_f.should eq(item.amount)
        find("#price_#{idx}")[:value].to_f.should eq(item.price)
        page.find(:xpath, "//table//tbody//tr[#{idx + 1}]//td[5]").text.to_f.should eq(
          (item.amount * item.price).accounting_norm)
      end
      page.find(:xpath, "//table//tfoot//tr//td[2]").text.to_f.should eq(
        (waybill.items.inject(0) { |mem, item| mem += item.amount }))
      page.find(:xpath, "//table//tfoot//tr//td[4]").text.to_f.should eq(
        (waybill.items.inject(0) do |mem, item|
          mem += item.amount * item.price
          mem.accounting_norm
        end))
    end
  end

end

def should_present_waybill(waybills)
  check_group_content('#container_documents table', waybills) do |waybill|
    state =
        case waybill.state
          when Statable::UNKNOWN then I18n.t('views.statable.unknown')
          when Statable::INWORK then I18n.t('views.statable.inwork')
          when Statable::CANCELED then I18n.t('views.statable.canceled')
          when Statable::APPLIED then I18n.t('views.statable.applied')
          when Statable::REVERSED then I18n.t('views.statable.reversed')
        end
    [waybill.created.strftime('%Y-%m-%d'), waybill.document_id,
     waybill.distributor.name, waybill.storekeeper.tag,
     waybill.storekeeper_place.tag, state, waybill.sum.to_s]
  end
end

def should_present_waybill_with_resource(waybills)
  check_content('#container_documents table', waybills) do |waybill|
    state =
        case waybill.state
          when Statable::UNKNOWN then I18n.t('views.statable.unknown')
          when Statable::INWORK then I18n.t('views.statable.inwork')
          when Statable::CANCELED then I18n.t('views.statable.canceled')
          when Statable::APPLIED then I18n.t('views.statable.applied')
          when Statable::REVERSED then I18n.t('views.statable.reversed')
        end
    [waybill.created.strftime('%Y-%m-%d'), waybill.document_id, waybill.distributor.name,
     waybill.storekeeper.tag, waybill.storekeeper_place.tag, state, waybill.sum.to_s,
     waybill.resource_tag, waybill.resource_mu, waybill.resource_amount.to_s,
     (1 / Converter.float(waybill.resource_price)).accounting_norm.to_s,
     Converter.float(waybill.resource_sum).accounting_norm.to_s]
  end
end

feature "waybill", %q{
  As an user
  I want to manage waybills
}do

  before :each do
    create(:chart)
  end

  scenario "manage waybills", js: true do
    PaperTrail.enabled = true

    3.times do
      user = create(:user)
      create(:credential, user: user, document_type: Waybill.name)
    end
    3.times { create(:user) }

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click
    page.should_not have_xpath("//ul[@id='documents_list']")

    current_hash.should eq("documents/waybills/new")
    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.save')}']")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.back')}']")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.draft')}']")
    page.should_not have_xpath("//div[@class='paginate']")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    within("select[@id='waybill_ident_name']") do
      find("option[@value='MSRN']")
      page.should have_content("#{I18n.t('views.waybills.ident_name_MSRN')}")
      find("option[@value='VATIN']")
      page.should have_content("#{I18n.t('views.waybills.ident_name_VATIN')}")
    end

    within("select[@id='warehouses']") do
      Waybill.warehouses.each do |warehouse|
        page.should have_selector("option[@value='#{warehouse.id}']")
        page.should have_content("#{warehouse.tag}"+
                                 "(#{I18n.t('views.waybills.warehouse.storekeeper')}: "+
                                 "#{warehouse.storekeeper})")
      end
    end

    page.should have_selector("span[@id='page-title']")
    within('#page-title') do
      page.should have_content("#{I18n.t('views.waybills.page_title_new')}")
    end

    click_button(I18n.t('views.waybills.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content(
          "#{I18n.t('views.waybills.created_at')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.waybills.document_id')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.waybills.distributor')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.waybills.ident_value')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.waybills.distributor_place')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.waybills.warehouse.name')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.should have_datepicker("created")
    page.datepicker("created").prev_month.day(10)

    page.should have_selector("input[@id='waybill_document_id']")
    fill_in("waybill_document_id", :with => "1233321")

    within('#container_documents form') do
      6.times { create(:legal_entity) }
      items = LegalEntity.order("name").limit(6)
      check_autocomplete('waybill_entity', items, :name) do |entity|
        find('#waybill_ident_name')['value'].should eq(entity.identifier_name)
        find('#waybill_ident_value')['value'].should eq(entity.identifier_value)
      end

      items[0].update_attributes!(identifier_name: 'MSRN')
      fill_in('waybill_entity', :with => items[0].send(:name)[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
          "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      find('#waybill_ident_name')['value'].should eq(items[0].identifier_name)

      6.times { create(:place) }
      items = Place.order(:tag).limit(6)
      check_autocomplete("distributor_place", items, :tag)

      warehouse = Waybill.warehouses.first
      select("#{warehouse.tag}(#{I18n.t('views.waybills.warehouse.storekeeper')}: "+
             "#{warehouse.storekeeper})", from: "warehouses")
      find("#warehouses")[:value].should eq(warehouse.id.to_s)

      page.should have_xpath("//table")
      page.should_not have_selector("table tbody tr")
      page.should have_selector("table tfoot tr")
      page.should have_xpath("//table//tfoot//tr//td[contains(.//text()," +
                                 "'#{I18n.t('views.waybills.total')}')]")
      page.find(:xpath, "//table//tfoot//tr//td[2]").text.should eq("0")
      page.find(:xpath, "//table//tfoot//tr//td[4]").text.should eq("0")
      page.find(:xpath, "//fieldset[@class='with-legend']" +
          "//input[@value='#{I18n.t('views.waybills.add')}']").click
      page.should have_xpath("//table//tbody//tr")
      page.should have_xpath("//table//tbody//tr//td[@class='table-actions']")
      fill_in("tag_0", :with => "tag")
      fill_in("mu_0", :with => "mu")
      fill_in("count_0", :with => "0")
      fill_in("price_0", :with => "0")
      page.find("table thead tr").click
      page.find("#tag_0")["value"].should eq("tag")
      page.find("#mu_0")["value"].should eq("mu")
      page.find("#count_0")["value"].should eq("0")
      page.find("#price_0")["value"].should eq("0")
      page.find(:xpath, "//table//tbody//tr[1]//td[5]").text.should eq("0.00")
      fill_in("count_0", :with => "2")
      fill_in("price_0", :with => "4")
      fill_in("mu_0", :with => "mu1")
      page.find(:xpath, "//table//tbody//tr[1]//td[5]").text.should eq("8.00")
      page.find(:xpath, "//table//tfoot//tr//td[2]").text.should eq("2")
      page.find(:xpath, "//table//tfoot//tr//td[4]").text.should eq("8")
      page.find("table tbody tr td[@class='table-actions'] label").click
      page.has_no_selector?("#tag_0").should be_true
      page.has_no_selector?("#mu_0").should be_true
      page.has_no_selector?("#count_0").should be_true
      page.has_no_selector?("#price_0").should be_true
      page.should_not have_selector("table tbody tr")
    end

    click_button(I18n.t('views.waybills.save'))
    within("#container_documents form") do
      within("#container_notification") do
        page.should have_content("#{I18n.t(
                    'activerecord.attributes.waybill.items')} #{I18n.t(
                    'activerecord.errors.models.waybill.items.blank')}")
      end

      page.find(:xpath, "//fieldset[@class='with-legend']" +
          "//input[@value='#{I18n.t('views.waybills.add')}']").click
      fill_in("count_0", :with => "10")
      fill_in("price_0", :with => "100")
      fill_in("tag_0", :with => "tag_1")
      fill_in("mu_0", :with => "RUB")
      page.find(:xpath, "//table//tbody//tr[1]//td[5]").text.should eq("1000.00")
      page.find(:xpath, "//table//tfoot//tr//td[2]").text.should eq("10")
      page.find(:xpath, "//table//tfoot//tr//td[4]").text.should eq("1000")
      page.find(:xpath, "//fieldset[@class='with-legend']" +
          "//input[@value='#{I18n.t('views.waybills.add')}']").click
      fill_in("count_1", :with => "2.34")
      fill_in("price_1", :with => "2.35")
      fill_in("tag_1", :with => "tag_2")
      fill_in("mu_1", :with => "RUB2")
      page.find(:xpath, "//table//tbody//tr[2]//td[5]").text.should eq("5.50")
      page.find(:xpath, "//table//tfoot//tr//td[2]").text.should eq("12.34")
      page.find(:xpath, "//table//tfoot//tr//td[4]").text.should eq("1005.5")
    end
    lambda do
      page.find(:xpath, "//div[@class='actions']" +
                  "//input[@value='#{I18n.t('views.waybills.save')}']").click
      wait_for_ajax
      wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    end.should change(Waybill, :count).by(1)

    show_waybill(Waybill.first)

    PaperTrail.enabled = false
  end

  scenario "storekeeper should not input his entity and place", js: true do
    PaperTrail.enabled = true

    Waybill.delete_all
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Waybill.name)
    page_login user.email, password

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click
    page.should_not have_xpath("//ul[@id='documents_list']")

    within('#container_documents form') do
      page.datepicker("created").prev_month.day(10)
      fill_in("waybill_document_id", :with => "1233321")
      item = create(:legal_entity)
      fill_in('waybill_entity', :with => item.name[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
                      "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      item = create(:place)
      fill_in('distributor_place', :with => item.tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
                      "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end

      find("#warehouses")[:value].should eq(credential.id.to_s)
      find("#warehouses")[:disabled].should eq("true")

      page.find(:xpath, "//fieldset[@class='with-legend']//input[@value='#{
                          I18n.t('views.waybills.add')
                        }']").click
      fill_in("tag_0", :with => "tag_1")
      fill_in("mu_0", :with => "RUB")
      fill_in("count_0", :with => "0")
      fill_in("price_0", :with => "100")


      page.find(:xpath, "//div[@class='actions']//input[@value='#{
                          I18n.t('views.waybills.save')
                        }']").click

      within("#container_notification") do
        page.should have_content("#{I18n.t('views.waybills.count')} : #{I18n.t(
            'errors.messages.greater_than', count: 0)}")
      end

      fill_in("count_0", :with => "-1")

      within("#container_notification") do
        page.should have_content("#{I18n.t('views.waybills.count')} : #{I18n.t(
            'errors.messages.greater_than', count: 0)}")
      end

      fill_in("count_0", :with => "0.37")
    end

    lambda do
      page.find(:xpath, "//div[@class='actions']//input[@value='#{
                          I18n.t('views.waybills.save')
                        }']").click
      wait_for_ajax
      wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    end.should change(Waybill, :count).by(1)

    within('div.comments') do
      page.should have_content(I18n.t('layouts.comments.comments'))

      fill_in('message', with: 'My first comment')
      click_button_and_wait(I18n.t('layouts.comments.save'))

      comment = Waybill.first.comments(:force_update).first
      within('fieldset fieldset') do
        page.should have_content(comment.user.entity.tag +
          " #{I18n.t('layouts.comments.at')} " +
          comment.created_at.strftime('%Y-%m-%d %H:%M:%S').to_s)
        within('span') { page.should have_content(comment.message) }
      end
    end

    PaperTrail.enabled = false
  end

  scenario 'applying waybills', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!

    page_login
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Waybill - #{wb.storekeeper.tag}')]").click
    click_button_and_wait(I18n.t('views.waybills.apply'))

    wait_until_hash_changed_to "documents/waybills/#{wb.id}"
    page.should have_no_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.waybills.apply')}']")
    find_field('state').value.should eq(I18n.t('views.statable.applied'))

    PaperTrail.enabled = false
  end

  scenario 'canceling waybills', js: true do
    PaperTrail.enabled = true

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!

    page_login
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Waybill - #{wb.storekeeper.tag}')]").click
    click_button_and_wait(I18n.t('views.waybills.cancel'))
    wait_until_hash_changed_to "documents/waybills/#{wb.id}"
    page.should have_no_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.waybills.cancel')}']")
    find_field('state').value.should eq(I18n.t('views.statable.canceled'))
    click_link I18n.t('views.home.logout')

    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    page_login
    visit("#documents/waybills/#{wb.id}")
    click_button_and_wait(I18n.t('views.waybills.cancel'))
    wait_until_hash_changed_to "documents/waybills/#{wb.id}"
    visit("#documents/waybills/#{wb.id}")
    page.should have_no_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.waybills.cancel')}']")
    find_field('state').value.should eq(I18n.t('views.statable.reversed'))
    click_link I18n.t('views.home.logout')

    PaperTrail.enabled = false
  end

  scenario 'view waybills', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times do |i|
      wb = build(:waybill)
      wb.add_item(tag: "test resource##{i}", mu: "test mu", amount: 200+i, price: 100+i)
      wb.save!
    end

    waybills = Waybill.limit(per_page)
    count = Waybill.count

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
       "not(contains(@style, 'display: none'))]/li[@id='waybills']/a").click

    current_hash.should eq('waybills')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
      "/ul[@id='slide_menu_deals']" +
      "/li[@id='waybills' and @class='sidebar-selected']")

    titles = [I18n.t('views.waybills.created_at'),
              I18n.t('views.waybills.document_id'),
              I18n.t('views.waybills.distributor'),
              I18n.t('views.waybills.storekeeper'),
              I18n.t('views.waybills.storekeeper_place'),
              I18n.t('views.statable.state')]
    check_header('#container_documents table', titles + [I18n.t('views.waybills.sum')])


    page.should have_selector("table tfoot tr")
    page.should have_xpath("//table//tfoot//tr//td[contains(.//text()," +
                               "'#{I18n.t('views.waybills.total')}')]")
    page.find(:xpath, "//table//tfoot//tr//td[2]").text.to_f.should eq(Waybill.total)

    page.find("#show-filter").click
    within('#filter-area') do
      titles.each do |title|
        page.should have_content(title)
      end

      fill_in('filter_created_at', with: waybills[3].created.strftime('%Y-%m-%d'))
      fill_in('filter_document_id', with: waybills[3].document_id)
      fill_in('filter_distributor', with: waybills[3].distributor.name)
      fill_in('filter_storekeeper', with: waybills[3].storekeeper.tag)
      fill_in('filter_storekeeper_place', with: waybills[3].storekeeper_place.tag)
      fill_in('filter_resource_name', with: waybills[3].items[0].resource.tag)
      select(I18n.t('views.statable.inwork'), from: 'filter_state')

      click_button(I18n.t('views.home.search'))
    end

    should_present_waybill([waybills[3]])
    check_paginate("div[@class='paginate']", 1, 1)

    page.find("#show-filter").click

    within('#filter-area') do
      find('#filter_created_at')['value'].should eq(waybills[3].created.strftime('%Y-%m-%d'))
      find('#filter_document_id')['value'].should eq(waybills[3].document_id)
      find('#filter_distributor')['value'].should eq(waybills[3].distributor.name)
      find('#filter_storekeeper')['value'].should eq(waybills[3].storekeeper.tag)
      find('#filter_storekeeper_place')['value'].should eq(waybills[3].storekeeper_place.tag)
      find('#filter_state')['value'].should eq('1')
      find('#filter_resource_name')['value'].should eq(waybills[3].items[0].resource.tag)

      page.find("#clear_filter").click

      find('#filter_created_at')['value'].should eq('')
      find('#filter_document_id')['value'].should eq('')
      find('#filter_distributor')['value'].should eq('')
      find('#filter_storekeeper')['value'].should eq('')
      find('#filter_storekeeper_place')['value'].should eq('')
      find('#filter_state')['value'].should eq('')
      find('#filter_resource_name')['value'].should eq('')

      click_button(I18n.t('views.home.search'))
    end

    should_present_waybill(waybills)
    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")

    waybills = Waybill.limit(per_page).offset(per_page)
    should_present_waybill(waybills)
    prev_page("div[@class='paginate']")

    page.find(:xpath, "//table//tbody//td[contains(.//text(),"+
        " '#{Waybill.first.document_id}')]").click_and_wait
    show_waybill(Waybill.first)


    waybills = WaybillReport.with_resources.select_all.limit(per_page)
    count = WaybillReport.with_resources.count
    total = WaybillReport.with_resources.total

    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
        "not(contains(@style, 'display: none'))]/li[@id='waybills']/a").click

    current_hash.should eq('waybills')

    page.find("#table_view").click_and_wait
    current_hash.should eq('waybills?view=table')

    titles = [I18n.t('views.waybills.created_at'),
              I18n.t('views.waybills.document_id'),
              I18n.t('views.waybills.distributor'),
              I18n.t('views.waybills.storekeeper'),
              I18n.t('views.waybills.storekeeper_place'),
              I18n.t('views.statable.state'),
              I18n.t('views.waybills.resource.tag'),
              I18n.t('views.waybills.resource.mu'),
              I18n.t('views.waybills.resource.amount'),
              I18n.t('views.waybills.resource.price'),
              I18n.t('views.waybills.resource.sum')]
    check_header('#container_documents table', titles)

    page.should have_selector("table tfoot tr")
    page.should have_xpath("//table//tfoot//tr//td[contains(.//text()," +
                               "'#{I18n.t('views.waybills.total')}')]")
    page.find(:xpath, "//table//tfoot//tr//td[2]").text.to_f.should eq(total)

    page.find("#show-filter").click
    within('#filter-area') do
      fill_in('filter_created_at', with: waybills[3].created.strftime('%Y-%m-%d'))
      fill_in('filter_document_id', with: waybills[3].document_id)
      fill_in('filter_distributor', with: waybills[3].distributor.name)
      fill_in('filter_storekeeper', with: waybills[3].storekeeper.tag)
      fill_in('filter_storekeeper_place', with: waybills[3].storekeeper_place.tag)
      fill_in('filter_resource_name', with: waybills[3].items[0].resource.tag)
      select(I18n.t('views.statable.inwork'), from: 'filter_state')

      click_button_and_wait(I18n.t('views.home.search'))
    end

    should_present_waybill_with_resource([waybills[3]])

    check_paginate("div[@class='paginate']", 1, 1)

    page.find("#show-filter").click

    within('#filter-area') do
      find('#filter_created_at')['value'].should eq(waybills[3].created.strftime('%Y-%m-%d'))
      find('#filter_document_id')['value'].should eq(waybills[3].document_id)
      find('#filter_distributor')['value'].should eq(waybills[3].distributor.name)
      find('#filter_storekeeper')['value'].should eq(waybills[3].storekeeper.tag)
      find('#filter_storekeeper_place')['value'].should eq(waybills[3].storekeeper_place.tag)
      find('#filter_state')['value'].should eq('1')
      find('#filter_resource_name')['value'].should eq(waybills[3].items[0].resource.tag)

      page.find("#clear_filter").click

      find('#filter_created_at')['value'].should eq('')
      find('#filter_document_id')['value'].should eq('')
      find('#filter_distributor')['value'].should eq('')
      find('#filter_storekeeper')['value'].should eq('')
      find('#filter_storekeeper_place')['value'].should eq('')
      find('#filter_state')['value'].should eq('')
      find('#filter_resource_name')['value'].should eq('')

      click_button_and_wait(I18n.t('views.home.search'))
    end

    should_present_waybill_with_resource(waybills)

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")

    waybills = WaybillReport.with_resources.select_all.limit(per_page).offset(per_page)
    should_present_waybill_with_resource(waybills)

    prev_page("div[@class='paginate']")

  end

  scenario "storekeeper should view only items created by him", js: true do
    PaperTrail.enabled = true

    Waybill.delete_all
    password = "password"
    user = create(:user, password: password)
    credential = create(:credential, user: user, document_type: Waybill.name)
    page_login user.email, password

    12.times do |i|
      wb = build(:waybill, storekeeper: i % 2 == 0 ? user.entity : create(:entity),
                 storekeeper_place: i % 4 == 0 ? credential.place : create(:place))
      wb.add_item(tag: "test resource##{i}", mu: "test mu", amount: 200+i, price: 100+i)
      wb.save!
    end

    waybills = Waybill.by_warehouse(credential.place)
    waybills.count.should eq(3)
    waybills_not_visible = Waybill.where{id.not_in(waybills.select(:id))}

    page.find('#btn_slide_lists').click
    page.find(:xpath, "//ul//li[@id='waybills']/a").click

    current_hash.should eq('waybills')
    page.should have_xpath("//ul//li[@id='waybills' and @class='sidebar-selected']")

    within('#container_documents table') do
      within('tbody') do
        waybills.each do |waybill|
          page.should have_content(waybill.created.strftime('%Y-%m-%d'))
          page.should have_content(waybill.document_id)
          page.should have_content(waybill.distributor.name)
          page.should have_content(waybill.storekeeper.tag)
          page.should have_content(waybill.storekeeper_place.tag)
          state =
            case waybill.state
              when Statable::UNKNOWN then I18n.t('views.statable.unknown')
              when Statable::INWORK then I18n.t('views.statable.inwork')
              when Statable::CANCELED then I18n.t('views.statable.canceled')
              when Statable::APPLIED then I18n.t('views.statable.applied')
            end
          page.should have_content(state)
        end
        waybills_not_visible.each do |waybill|
          page.should_not have_content(waybill.document_id)
          page.should_not have_content(waybill.distributor.name)
        end
      end
    end

    waybills_table = WaybillReport.with_resources.select_all.by_warehouse(credential.place)
    waybills_table.count.should eq(3)

    page.find("#table_view").click_and_wait

    current_hash.should eq('waybills?view=table')
    page.should have_xpath("//ul//li[@id='waybills' and @class='sidebar-selected']")

    should_present_waybill_with_resource(waybills_table)
    within('#container_documents table') do
      within('tbody') do
        waybills_not_visible.each do |waybill|
          page.should_not have_content(waybill.document_id)
          page.should_not have_content(waybill.distributor.name)
        end
      end
    end

    click_link I18n.t('views.home.logout')

    password = "password"
    user = create(:user, password: password, entity: Waybill.first.storekeeper)
    page_login user.email, password

    page.find('#btn_slide_lists').click
    page.should_not have_xpath("//ul//li[@id='waybills']")

    PaperTrail.enabled = false
  end

  scenario "views waybill's resources'", js: true do
    per_page = Settings.root.per_page

    wb = build(:waybill)
    wb2 = build(:waybill)

    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 100+i, amount: 10+i)
    end

    wb.save!
    wb.apply

    (0..per_page).each { |i|
      wb2.add_item(tag: "resource##{i}", mu: "mu##{i}", price: 500+i, amount: 50+i)
    }

    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click_and_wait
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
        "not(contains(@style, 'display: none'))]/li[@id='waybills']/a").click_and_wait
    current_hash.should eq('waybills')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                               "/ul[@id='slide_menu_deals']" +
                               "/li[@id='waybills' and @class='sidebar-selected']")

    should_present_waybill([wb, wb2])
    within('#container_documents table tbody') do
      page.should have_selector(:xpath, ".//tr//td[@class='tree-actions']
                        //div[@class='ui-corner-all ui-state-hover']
                        //span[@class='ui-icon ui-icon-circle-plus']", count: 2)
      find(:xpath, ".//tr[3]//td[@class='tree-actions']").click
    end
    resources2 = wb2.items[0, per_page]
    count = wb2.items.count
    count.should eq(per_page + 1)

    check_paginate("#resource_#{wb2.id} div[@class='paginate']", count, per_page)
    check_content("#resource_#{wb2.id} table[@class='inner-table']", resources2) do |res|
      [res.resource.tag, res.resource.mu, res.amount.to_i, res.price.to_i,
       (res.price * res.amount).to_i]
    end
    next_page("#resource_#{wb2.id} div[@class='paginate']")
    resources2 = wb2.items[per_page, per_page]
    check_content("#resource_#{wb2.id} table[@class='inner-table']", resources2) do |res|
      [res.resource.tag, res.resource.mu, res.amount.to_i, res.price.to_i,
       (res.price * res.amount).to_i]
    end
    within('#container_documents table tbody') do
      find(:xpath, ".//tr[3]//td[@class='tree-actions']").click
      page.should_not have_selector("#resource_#{wb2.id}")
    end
  end

  scenario 'sort waybills', js: true do
    moscow = create(:place, tag: 'Moscow')
    kiev = create(:place, tag: 'Kiev')
    amsterdam = create(:place, tag: 'Amsterdam')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')
    antonov = create(:entity, tag: 'Antonov')
    ivanov_legal = create(:legal_entity, name: 'Ivanov')
    petrov_legal = create(:legal_entity, name: 'Petrov')
    antonov_legal = create(:legal_entity, name: 'Antonov')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 1,
                distributor: petrov_legal, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 3,
                distributor: antonov_legal, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb2.save!

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 2,
                distributor: ivanov_legal, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb3.save!
    wb3.apply

    page_login
    page.find('#btn_slide_lists').click
    page.find('#deals').click
    page.find(:xpath, "//ul[@id='slide_menu_deals' and " +
        "not(contains(@style, 'display: none'))]/li[@id='waybills']/a").click

    current_hash.should eq('waybills')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/ul[@id='slide_menu_deals']" +
                           "/li[@id='waybills' and @class='sidebar-selected']")

    test_order = lambda do |field, type|
      waybills = Waybill.order_by(field: field, type: type).all
      within('#container_documents table') do
        within('thead tr') do
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
      should_present_waybill(waybills)
    end

    test_order.call('created','asc')
    test_order.call('created','desc')

    test_order.call('document_id','asc')
    test_order.call('document_id','desc')

    test_order.call('distributor','asc')
    test_order.call('distributor','desc')

    test_order.call('storekeeper','asc')
    test_order.call('storekeeper','desc')

    test_order.call('storekeeper_place','asc')
    test_order.call('storekeeper_place','desc')


    page.find("#table_view").click
    current_hash.should eq('waybills?view=table')

    test_order_with_resource = lambda do |field, type|
      waybills = WaybillReport.with_resources.select_all.order_by(field: field, type: type)
      within('#container_documents table') do
        within('thead tr') do
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
      should_present_waybill_with_resource(waybills)
    end

    test_order_with_resource.call('created','asc')
    test_order_with_resource.call('created','desc')

    test_order_with_resource.call('document_id','asc')
    test_order_with_resource.call('document_id','desc')

    test_order_with_resource.call('distributor','asc')
    test_order_with_resource.call('distributor','desc')

    test_order_with_resource.call('storekeeper','asc')
    test_order_with_resource.call('storekeeper','desc')

    test_order_with_resource.call('storekeeper_place','asc')
    test_order_with_resource.call('storekeeper_place','desc')

    test_order_with_resource.call('resource_tag','asc')
    test_order_with_resource.call('resource_tag','desc')

    test_order_with_resource.call('resource_mu','asc')
    test_order_with_resource.call('resource_mu','desc')

    test_order_with_resource.call('resource_amount','asc')
    test_order_with_resource.call('resource_amount','desc')

    test_order_with_resource.call('resource_price','asc')
    test_order_with_resource.call('resource_price','desc')

    test_order_with_resource.call('resource_sum','asc')
    test_order_with_resource.call('resource_sum','desc')
  end

  scenario 'comment waybill when user doing action', js: true do
    PaperTrail.enabled = true

    password = "password"
    user = create(:user, password: password)
    create(:credential, user: user, document_type: Waybill.name)
    page_login user.email, password

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click_and_wait
    page.should_not have_xpath("//ul[@id='documents_list']")

    within('#container_documents form') do
      page.datepicker("created").prev_month.day(10)
      fill_in("waybill_document_id", :with => "123121")
      item = create(:legal_entity)
      fill_in('waybill_entity', :with => item.name[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
          "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      item = create(:place)
      fill_in('distributor_place', :with => item.tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
          "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end

      page.find(:xpath, "//fieldset[@class='with-legend']//input[@value='#{I18n.
          t('views.waybills.add')}']").click
      fill_in("tag_0", :with => "res_tag")
      fill_in("mu_0", :with => "RUB")
      fill_in("count_0", :with => "200")
      fill_in("price_0", :with => "100")
    end

    lambda do
      page.find(:xpath, "//div[@class='actions']//input[@value='#{I18n.
          t('views.waybills.save')}']").click_and_wait
      wait_for_ajax
      wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    end.should change(Waybill, :count).by(1)

    within('#container_documents') do
      within("div[@class='comments']") do
        page.should have_content(I18n.t("activerecord.attributes.waybill.comment.create"))
      end
    end

    click_button_and_wait(I18n.t('views.waybills.apply'))

    wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    wait_until { !page.has_xpath?("//div[@class='actions']/input[@value='#{I18n.t(
            'views.waybills.apply')}']") }
    within('#container_documents') do
      within("div[@class='comments']") do
        page.should have_content(I18n.t("activerecord.attributes.waybill.comment.apply"))
      end
    end

    click_button_and_wait(I18n.t('views.waybills.cancel'))

    wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    wait_until { !page.has_xpath?("//div[@class='actions']/input[@value='#{I18n.t(
            'views.waybills.apply')}']") }
    within('#container_documents') do
      within("div[@class='comments']") do
        page.should have_content(I18n.t("activerecord.attributes.waybill.comment.reverse"))
      end
    end

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click_and_wait
    page.should_not have_xpath("//ul[@id='documents_list']")

    within('#container_documents form') do
      page.datepicker("created").prev_month.day(10)
      fill_in("waybill_document_id", :with => "123122")
      item = create(:legal_entity)
      fill_in('waybill_entity', :with => item.name[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
          "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      item = create(:place)
      fill_in('distributor_place', :with => item.tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
          "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end

      page.find(:xpath, "//fieldset[@class='with-legend']//input[@value='#{I18n.
          t('views.waybills.add')}']").click
      fill_in("tag_0", :with => "res_tag1")
      fill_in("mu_0", :with => "RUB")
      fill_in("count_0", :with => "200")
      fill_in("price_0", :with => "100")
    end

    lambda do
      page.find(:xpath, "//div[@class='actions']//input[@value='#{I18n.
          t('views.waybills.save')}']").click_and_wait
      wait_for_ajax
      wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    end.should change(Waybill, :count).by(1)

    click_button_and_wait(I18n.t('views.waybills.cancel'))

    wait_until_hash_changed_to "documents/waybills/#{Waybill.last.id}"
    wait_until { !page.has_xpath?("//div[@class='actions']/input[@value='#{I18n.t(
            'views.waybills.apply')}']") }
    within('#container_documents') do
      within("div[@class='comments']") do
        page.should have_content(I18n.t("activerecord.attributes.waybill.comment.cancel"))
      end
    end

    PaperTrail.enabled = false
  end
end
