# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "waybill", %q{
  As an user
  I want to manage waybills
}do

  before :each do
    create(:chart)
  end

  scenario "manage waybills", js: true do
    PaperTrail.enabled = true

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    current_hash.should eq("documents/waybills/new")
    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.save')}']")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.back')}']")
    page.should have_selector("input[@value='#{I18n.t('views.waybills.draft')}']")
    page.should have_xpath("//div[@class='paginate' and contains(@style, 'display: none')]")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    within("select[@id='waybill_ident_name']") do
      find("option[@value='MSRN']")
      page.should have_content("#{I18n.t('views.waybills.ident_name_MSRN')}")
      find("option[@value='VATIN']")
      page.should have_content("#{I18n.t('views.waybills.ident_name_VATIN')}")
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
          "#{I18n.t('views.waybills.storekeeper')} : #{I18n.t('errors.messages.blank')}")
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

      find("#storekeeper_place")[:disabled].should eq("true")

      3.times do
        user = create(:user)
        create(:credential, user: user, document_type: Waybill.name)
      end
      3.times { create(:user) }
      items = Credential.where(document_type: Waybill.name).all.collect { |c| c.user.entity }
      check_autocomplete("storekeeper_entity", items, :tag, true)
      fill_in('storekeeper_entity', :with => items[0].tag[0..1])
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
                     "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      find("#storekeeper_entity")[:value].should eq(items[0].tag)
      find("#storekeeper_place")[:value].should eq(
        User.where(entity_id: items[0].id).first.
          credentials.where(document_type: Waybill.name).first.place.tag)

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
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(Waybill, :count).by(1)

    page.find(:xpath, "//td[@class='cell-title' and " +
                  "contains(.//text(), '#{Waybill.name}')]").click
    current_hash.should eq("documents/waybills/" + Waybill.first.id.to_s)

    page.should have_selector("span[@id='page-title']")
    within('#page-title') do
      page.should have_content("#{I18n.t('views.waybills.page_title_show')}")
    end

    within("#container_documents form") do
      find("#created")[:value].should eq(Waybill.first.created.strftime("%d.%m.%Y"))
      find("#waybill_document_id")[:value].should eq(Waybill.first.document_id)
      find("#waybill_entity")[:value].should eq(Waybill.first.distributor.name)
      find("#waybill_ident_name")[:value].should eq(Waybill.first.distributor.identifier_name)
      find("#waybill_ident_value")[:value].should eq(Waybill.first.distributor.identifier_value)
      find("#distributor_place")[:value].should eq(Waybill.first.distributor_place.tag)
      find("#storekeeper_entity")[:value].should eq(Waybill.first.storekeeper.tag)
      find("#storekeeper_place")[:value].should eq(Waybill.first.storekeeper_place.tag)

      find("#created")[:disabled].should eq("true")
      find("#waybill_document_id")[:disabled].should eq("true")
      find("#waybill_entity")[:disabled].should eq("true")
      find("#waybill_ident_name")[:disabled].should eq("true")
      find("#waybill_ident_value")[:disabled].should eq("true")
      find("#distributor_place")[:disabled].should eq("true")
      find("#storekeeper_entity")[:disabled].should eq("true")
      find("#storekeeper_place")[:disabled].should eq("true")

      within("table tbody") do
        find("#tag_0")[:value].should eq(Waybill.first.items[0].resource.tag)
        find("#mu_0")[:value].should eq(Waybill.first.items[0].resource.mu)
        find("#count_0")[:value].should eq(Waybill.first.items[0].amount.to_i.to_s)
        find("#price_0")[:value].should eq(Waybill.first.items[0].price.to_i.to_s)
        page.find(:xpath, "//table//tbody//tr[1]//td[5]").text.should eq(
          "%.2f" % (Waybill.first.items[0].amount * Waybill.first.items[0].price))
        page.find(:xpath, "//table//tbody//tr[2]//td[5]").text.should eq(
          "%.2f" % (Waybill.first.items[1].amount * Waybill.first.items[1].price))
        page.find(:xpath, "//table//tfoot//tr//td[2]").text.should eq(
          "%.2f" % (Waybill.first.items.inject(0) { |mem, item| mem += item.amount }))
        page.find(:xpath, "//table//tfoot//tr//td[4]").text.should eq(
          (Waybill.first.items.inject(0) do |mem, item|
            mem += item.amount * item.price
            mem.accounting_norm
          end).to_s)
      end
    end

    PaperTrail.enabled = false
  end

  scenario "storekeeper should not input his entity and place", js: true do
    PaperTrail.enabled = true

    Waybill.delete_all
    password = "password"
    user = create(:user, password: password)
    create(:credential, user: user, document_type: Waybill.name)
    page_login user.email, password

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

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

      find("#storekeeper_entity")[:value].should eq(user.entity.tag)
      find("#storekeeper_place")[:value].should eq(
        user.credentials(:force_update).where(document_type: Waybill.name).first.place.tag)
      find("#storekeeper_entity")[:disabled].should eq("true")
      find("#storekeeper_place")[:disabled].should eq("true")

      page.find(:xpath, "//fieldset[@class='with-legend']//input[@value='#{
                          I18n.t('views.waybills.add')
                        }']").click
      fill_in("tag_0", :with => "tag_1")
      fill_in("mu_0", :with => "RUB")
      fill_in("count_0", :with => "10")
      fill_in("price_0", :with => "100")
    end
    lambda do
      page.find(:xpath, "//div[@class='actions']//input[@value='#{
                          I18n.t('views.waybills.save')
                        }']").click
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(Waybill, :count).by(1)

    page.find("td[@class='cell-entity']").click

    within('div.comments') do
      page.should have_content(I18n.t('layouts.comments.comments'))

      fill_in('message', with: 'My first comment')
      click_button(I18n.t('layouts.comments.save'))

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
    click_button(I18n.t('views.waybills.apply'))
    page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Waybill - #{wb.storekeeper.tag}')]").click
    page.should have_xpath("//div[@class='actions']/input[@value='#{I18n.t(
        'views.waybills.apply')}' and contains(@style, 'display: none')]")
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
    click_button(I18n.t('views.waybills.cancel'))
    page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Waybill - #{wb.storekeeper.tag}')]").click
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.waybills.cancel')}' and contains(@style, 'display: none')]")
    find_field('state').value.should eq(I18n.t('views.statable.canceled'))

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

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.waybills.created_at'))
        page.should have_content(I18n.t('views.waybills.document_id'))
        page.should have_content(I18n.t('views.waybills.distributor'))
        page.should have_content(I18n.t('views.waybills.storekeeper'))
        page.should have_content(I18n.t('views.waybills.storekeeper_place'))
        page.should have_content(I18n.t('views.statable.state'))
      end

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

    waybills = Waybill.limit(per_page).offset(per_page)
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page
      page.should have_selector('tr', count: count_on_page)
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
