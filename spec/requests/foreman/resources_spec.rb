# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'foreman/resources', %q{
  As an user
  I want to view foreman/resources
} do
  scenario 'view resources', js: true do
    per_page = Settings.root.per_page
    create :chart
    PaperTrail.enabled = true
    place = create(:place, tag: 'place')
    user = create(:user)
    create(:credential, user: user, place: place, document_type: Allocation.name)
    create(:credential, user: user, place: place, document_type: Waybill.name)
    PaperTrail.whodunnit = user
    foreman = create(:user)
    create(:credential, user: foreman, place: place, document_type: WarehouseForemanReport.name)
    wb = build(:waybill,  storekeeper_place: place)
    (0..per_page).each do |i|
      wb.add_item(tag: "nails#{i}", amount: 500, price: 666, mu: 'pcs')
    end
    wb.save!
    wb.apply
    al = Allocation.new(created: Date.today,
                        foreman_id: foreman.entity_id,
                        foreman_type: Entity.name,
                        foreman_place_id: place.id,
                        storekeeper_id: wb.storekeeper.id,
                        storekeeper_type: wb.storekeeper.class.name,
                        storekeeper_place_id: wb.storekeeper_place.id)
    (0..per_page).each do |i|
      al.add_item(tag: "nails#{i}", mu: 'pcs', amount: 500)
    end
    al.save
    al.apply
    page_login(foreman.email, foreman.crypted_password)
    find("#btn_slide_lists").click
    click_link I18n.t('views.home.foreman_report')
    titles = [I18n.t('views.warehouses.foremen.report.resource.name'),
              I18n.t('views.warehouses.foremen.report.resource.mu'),
              I18n.t('views.warehouses.foremen.report.amount'),
              I18n.t('views.warehouses.foremen.report.price'),
              I18n.t('views.warehouses.foremen.report.sum')]
    check_header("#container_documents table", titles)

    page.should have_datepicker("foremen_filter_from")
    page.should have_datepicker("foremen_filter_to")

    check_paginate("div[@class='paginate']", per_page + 1, per_page)

    args = {  warehouse_id: 1,
              foreman_id: 30,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 1, per_page: per_page }
    resources = WarehouseForemanReport.all(args)

    within('#container_documents table') do
      page.should have_selector('tbody tr', count: per_page)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    next_page("div[@class='paginate']")

    args = {  warehouse_id: 1,
              foreman_id: 30,
              start: DateTime.current.beginning_of_month,
              stop: DateTime.current,
              page: 2, per_page: per_page }
    resources = WarehouseForemanReport.all(args)
    within('#container_documents table') do
      page.should have_selector('tbody tr', count: 1)
      resources.each do |res|
        page.should have_content(res.resource.tag)
        page.should have_content(res.resource.mu)
        page.should have_content(res.price.to_i)
        page.should have_content(res.amount.to_i)
        page.should have_content (res.price * res.amount).to_i
      end
    end

    page.datepicker("foremen_filter_to").prev_month.day(10)

    within('#container_documents table') do
      page.should_not have_selector('tbody tr')
    end

    PaperTrail.whodunnit = nil
    PaperTrail.enabled = false
  end
end
