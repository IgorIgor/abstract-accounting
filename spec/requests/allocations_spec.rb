# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'allocation', %q{
  As an user
  I want to view allocations
} do

  scenario 'view allocations', js: true do
    per_page = Settings.root.per_page
    create(:chart)
    user = create(:user)
    credential = create(:credential, user: user, document_type: Allocation.name)
    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
    (per_page + 1).times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click
    current_hash.should eq('documents/allocations/new')

    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.save')}']")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.back')}']")
    page.should have_selector("input[@value='#{I18n.t('views.allocations.draft')}']")
    page.should have_xpath("//div[@class='paginate' and contains(@style, 'display: none')]")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    page.should have_selector("span[@id='page-title']")
    within('#page-title') do
      page.should have_content("#{I18n.t('views.allocations.page_title_new')}")
    end

    page.should have_datepicker("created")
    page.datepicker("created").prev_month.day(10)

    within("#container_documents form") do
      page.should have_no_selector('#available-resources tbody tr')

      find('#storekeeper_place')[:disabled].should eq("true")
      fill_in('storekeeper_entity', with: 'fail')
      page.has_css?("#storekeeper_entity", value: '').should be_true
      page.should have_no_selector('#available-resources tbody tr')

      fill_in('storekeeper_entity', with: 'fail')
      page.has_css?("#storekeeper_place", value: '').should be_true
      page.should have_no_selector('#available-resources tbody tr')

      6.times.collect { create(:place) }
      items = Place.find(:all, order: :tag, limit: 5)
      check_autocomplete("foreman_place", items, :tag)

      3.times do
        user = create(:user)
        create(:credential, user: user, document_type: Allocation.name)
      end
      3.times { create(:user) }
      items = Credential.where(document_type: Allocation.name).
          all.collect { |c| c.user.entity }
      check_autocomplete("storekeeper_entity", items, :tag, true)
      fill_in('storekeeper_entity', :with => items[0].tag)
      within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
                     "contains(@style, 'display: block')]") do
        all(:xpath, ".//li//a")[0].click
      end
      find("#storekeeper_entity")[:value].should eq(items[0].tag)
      find("#storekeeper_place")[:value].should eq(
        User.where(entity_id: items[0].id).first.
          credentials.where(document_type: Allocation.name).first.place.tag)

      items = Entity.all(order: :tag, limit: 5)
      check_autocomplete("foreman_entity", items, :tag)
    end

    within("#container_documents") do
      unless page.find("#storekeeper_entity").value == wb.storekeeper.tag
        fill_in_autocomplete('storekeeper_entity', wb.storekeeper.tag)
      end


      wh = Warehouse.all(where: { storekeeper_id: {
                                    equal: wb.storekeeper.id },
                                  storekeeper_place_id: {
                                    equal: wb.storekeeper_place.id }})
      count = Warehouse.count(where: { storekeeper_id: {
                                         equal: wb.storekeeper.id },
                                      storekeeper_place_id: {
                                         equal: wb.storekeeper_place.id }})
      (0..(count/per_page).ceil).each do |p|
        wh[p*per_page...p*per_page+per_page].each_with_index do |w, i|
          tr = page.all('#available-resources tbody tr')[i]
          tr.should have_content(w.tag)
          tr.should have_content(w.mu)
          tr.should have_content(w.real_amount.to_i)
        end
        click_button('>')
      end

      within("div[@class='paginate']") do
        find_button('>')[:disabled].should eq('true')
      end

      (count/per_page).ceil.downto(0).each do |p|
        wh[p*per_page...p*per_page+per_page].each_with_index do |w, i|
          tr = page.all('#available-resources tbody tr')[i]
          tr.should have_content(w.tag)
          tr.should have_content(w.mu)
          tr.should have_content(w.real_amount.to_i)
        end
        click_button('<')
      end

      within("#selected-resources") do
        page.should_not have_selector('tbody tr')
      end

      (0..count-1).each do |i|
        page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
        if i < count - 1
          if i < count - per_page
            page.should have_selector('#available-resources tbody tr', count: per_page)
          else
            page.should have_selector('#available-resources tbody tr', count: count-i-1)
          end
        else
          page.should_not have_selector('#available-resources tbody tr')
        end
        page.should have_selector('#selected-resources tbody tr', count: 1+i)
      end

      within("#available-resources") do
        page.all('tbody tr').each_with_index { |tr, i|
          tr.find("td input[@type='text']")[:value].should eq("#{100+i}")
        }
      end

      wb2 = build(:waybill)
      wb2.add_item(tag: "resource_2", mu: "mu_2", amount: 100, price: 10)
      wb2.save!
      wb2.apply

      wbs = Waybill.in_warehouse(where: { storekeeper_id: {
                                            equal: wb.storekeeper.id },
                                          storekeeper_place_id: {
                                            equal: wb.storekeeper_place.id }})

      page.find('#mode-waybills').click
      page.should have_no_selector('#available-resources')
      within('#available-resources-by-wb') do
        wbs.each_with_index do |w, idx|
          tr = page.all('tbody tr')[idx]
          tr.should have_content(w.document_id)
          tr.should have_content(w.created.strftime('%Y-%m-%d'))
          tr.should have_content(w.distributor.name)
          tr.should have_content(w.storekeeper.tag)
          tr.should have_content(w.storekeeper_place.tag)
        end

        page.find("td[@class='allocation-tree-actions-by-wb']").click
        within('table') do
          wbs[0].items.each_with_index do |item, idx|
            tr = page.all('tbody tr')[idx]
            tr.should have_content(item.resource.tag)
            tr.should have_content(item.resource.mu)
            tr.should have_content(item.amount.to_i)
          end
        end
      end

      within('#selected-resources tbody') do
        wb.items.each do |item|
          page.should have_content(item.resource.tag)
          page.should have_content(item.resource.mu)
          page.should have_content(item.amount.to_i)
        end
      end

      page.find('#mode-resources-by-wb').click
      page.should have_no_selector('#available-resources-by-wb')

      (0..count-1).each do |i|
        page.find("#selected-resources tbody tr td[@class='allocation-actions'] span").click
        if i < count-1
          page.should have_selector('#selected-resources tbody tr', count: count-i-1)
          page.should have_selector('#available-resources tbody tr', count: 1+i)
        else
          page.should_not have_selector('#selected-resources tbody tr')
        end
      end

      wb3 = build(:waybill, storekeeper: wb.storekeeper,
                                    storekeeper_place: wb.storekeeper_place)
      wb3.add_item(tag: 'resource#0', mu: 'mu0', amount: 27, price: 10)
      wb3.save!
      wb3.apply.should be_true

      wbs = Waybill.in_warehouse(where: { storekeeper_id: {
                                            equal: wb.storekeeper.id },
                                          storekeeper_place_id: {
                                            equal: wb.storekeeper_place.id }})

      page.find('#mode-waybills').click
      page.should have_no_selector('#available-resources')
      within('#available-resources-by-wb') do
        page.all('tbody tr').each do |tr|
          if tr.has_content?(wb.document_id) &&
             tr.has_content?(wb.created.strftime('%Y-%m-%d')) &&
             tr.has_content?(wb.distributor.name) &&
             tr.has_content?(wb.storekeeper.tag) &&
             tr.has_content?(wb.storekeeper_place.tag)
            tr.find("td[@class='allocation-actions-by-wb'] span").click
          end
        end
        within('tbody') do
          if wbs.count - 1 > 0
            page.should have_selector('tr', count: wbs.count - 1)
          else
            page.should_not have_selector('tr')
          end
        end
      end

      within('#selected-resources tbody') do
        page.all('tbody tr').each do |tr|
          if tr.has_content?('resource#0') &&
             tr.has_content?('mu0') &&
             tr.has_content?('127')
            tr.find('input')[:value].should eq('100')
          end
        end

        wb.items.each do |item|
          if item.resource.tag != "resource#0"
            page.should have_content(item.resource.tag)
            page.should have_content(item.resource.mu)
            page.should have_content(item.amount.to_i)
          end
        end
      end

      within('#available-resources-by-wb') do
        page.all('tbody tr').each do |tr|
          if tr.has_content?(wb3.document_id) &&
             tr.has_content?(wb3.created.strftime('%Y-%m-%d')) &&
             tr.has_content?(wb3.distributor.name) &&
             tr.has_content?(wb3.storekeeper.tag) &&
             tr.has_content?(wb3.storekeeper_place.tag)
            tr.find("td[@class='allocation-actions-by-wb'] span").click
          end
        end
      end

      within('#selected-resources') do
        page.all('tbody tr').each do |tr|
          if tr.has_content?('resource#0') &&
             tr.has_content?('mu0') &&
             tr.has_content?('127')
            tr.find('input')[:value].should eq('127')
          end
        end
      end
    end
  end

  scenario 'test allocations save', js: true do
    PaperTrail.enabled = true

    create(:chart)
    user = create(:user)
    credential = create(:credential, user: user, document_type: Allocation.name)
    wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place,
                         created: DateTime.current.change(year: 2011))
    wb.add_item(tag: 'roof', mu: 'm2', amount: 12, price: 100.0)
    wb.add_item(tag: 'roof2', mu: 'm2', amount: 12, price: 100.0)
    wb.save!
    wb.apply

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click

    click_button(I18n.t('views.allocations.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content(
          "#{I18n.t('views.allocations.created_at')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.allocations.storekeeper')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.allocations.foreman')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content(
          "#{I18n.t('views.allocations.foreman_place')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    page.datepicker("created").prev_month.day(10)

    within("#container_documents form") do
      fill_in_autocomplete('storekeeper_entity', wb.storekeeper.tag)
      fill_in("foreman_entity", :with =>"entity")
      fill_in("foreman_place", :with => "place")
    end

    within("#container_documents") do
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
    end

    lambda {
      click_button(I18n.t('views.allocations.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    }.should change(Allocation, :count).by(1)

    PaperTrail.enabled = false
  end

  scenario 'save distibution by non root user', js: true do
    PaperTrail.enabled = true

    create(:chart)
    wb = build(:waybill, created: DateTime.current.change(year: 2011))
    wb.add_item(tag: 'roof', mu: 'm2', amount: 12, price: 100.0)
    wb.add_item(tag: 'roof2', mu: 'm2', amount: 12, price: 100.0)
    wb.save!
    wb.apply

    password = "password"
    user = create(:user, password: password, entity: wb.storekeeper)
    create(:credential, place: wb.storekeeper_place, user: user,
                        document_type: Allocation.name)

    page_login user.email, password

    page.find("#btn_create").click
    page.find("a[@href='#documents/allocations/new']").click

    within("#container_documents form") do
      page.datepicker("created").prev_month.day(10)
      find("#storekeeper_entity")[:value].should eq(user.entity.tag)
      find("#storekeeper_place")[:value].should eq(wb.storekeeper_place.tag)
      find("#storekeeper_entity")[:disabled].should eq("true")
      find("#storekeeper_place")[:disabled].should eq("true")
      fill_in("foreman_entity", :with =>"entity")
      fill_in("foreman_place", :with => "place")
    end

    within("#container_documents") do
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
      page.find("#available-resources tbody tr td[@class='allocation-actions'] span").click
    end

    lambda {
      click_button(I18n.t('views.allocations.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    }.should change(Allocation, :count).by(1)

    PaperTrail.enabled = false
  end

  scenario 'show allocations', js: true do
    PaperTrail.enabled = true

    create(:chart)
    wb = build(:waybill)
    (0..4).each do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    (0..4).each do |i|
      ds.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 10+i)
    end
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    current_hash.should eq("documents/allocations/#{ds.id}")

    page.should have_selector("span[@id='page-title']")
    within('#page-title') do
      page.should have_content(
        "#{I18n.t('views.allocations.page_title_show')}")
    end

    within("#container_documents form") do
      #find("#created")[:value].should eq(ds.created.strftime("%m/%d/%Y"))
      find("#storekeeper_entity")[:value].should eq(ds.storekeeper.tag)
      find("#storekeeper_place")[:value].should eq(ds.storekeeper_place.tag)
      find("#foreman_entity")[:value].should eq(ds.foreman.tag)
      find("#foreman_place")[:value].should eq(ds.foreman_place.tag)
      find("#state")[:value].should eq(I18n.t('views.statable.inwork'))

      find("#created")[:disabled].should be_true
      find("#storekeeper_entity")[:disabled].should be_true
      find("#storekeeper_place")[:disabled].should be_true
      find("#foreman_entity")[:disabled].should be_true
      find("#foreman_place")[:disabled].should be_true
      find("#state")[:disabled].should be_true
    end

    within("#selected-resources tbody") do
      all(:xpath, './/tr').count.should eq(5)
      all(:xpath, './/tr').each_with_index {|tr, idx|
        tr.should have_content("resource##{idx}")
        tr.should have_content("mu#{idx}")
        tr.find(:xpath, './/input')[:value].should eq("#{10+idx}")
      }
    end

    PaperTrail.enabled = false
  end

  scenario 'applying allocations', js: true do
    PaperTrail.enabled = true

    create(:chart)
    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
      click_button(I18n.t('views.allocations.apply'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
      'views.allocations.apply')}' and contains(@style, 'display: none')]")
    PaperTrail.enabled = false
  end

  scenario 'canceling allocations', js: true do
    PaperTrail.enabled = true

    create(:chart)
    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    click_button(I18n.t('views.allocations.cancel'))
    page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Allocation - #{wb.storekeeper.tag}')]").click
    page.should have_xpath("//div[@class='actions']//input[@value='#{I18n.t(
        'views.allocations.cancel')}' and contains(@style, 'display: none')]")
    PaperTrail.enabled = false
  end

  scenario 'generate pdf', js: true do
    PaperTrail.enabled = true

    create(:chart)
    wb = build(:waybill)
    wb.add_item(tag: "test resource", mu: "test mu", amount: 100, price: 10)
    wb.save!
    wb.apply

    ds = build(:allocation, storekeeper: wb.storekeeper,
                            storekeeper_place: wb.storekeeper_place)
    ds.add_item(tag: "test resource", mu: "test mu", amount: 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
                      'Allocation - #{wb.storekeeper.tag}')]").click

    visit("#{allocation_path(ds)}.html")

    page.should have_selector("span [@class='description_element']")

    within('#person-list') do
      page.should have_content("#{ds.storekeeper.tag}")
      page.should have_content("#{ds.foreman.tag}")
    end

    within("table[@class='allocations'] tbody tr") do
      page.should have_content("test resource")
      page.should have_content("test mu")
      page.should have_content("10")
    end

    within("div[@class='date-block']") do
      page.should have_content(ds.created.strftime('%Y-%m-%d'))
    end

    within('#signature') do
      page.should have_content("#{ds.storekeeper.tag}")
      page.should have_content("#{ds.foreman.tag}")
    end

    PaperTrail.enabled = false
  end
end
