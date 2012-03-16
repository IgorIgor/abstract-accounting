# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "estimates", %q{
  As an user
  I want to manage estimates
} do

  scenario "manage estimates", :js => true do
    pending "disabled according to not complete estimate"
    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/estimates/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    current_hash.should eq("documents/estimates/new")
    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    page.find("#inbox")[:class].should_not eq("sidebar-selected")

    within("#container_documents form") do
      items = 6.times.collect { Factory(:legal_entity) } .sort
      check_autocomplete("estimate_entity", items, :name) do |entity|
        find("#estimate_ident_name")["value"].should eq(entity ? entity.identifier_name : "")
        find("#estimate_ident_value")["value"].should eq(entity ? entity.identifier_value : "")
      end
    end

    catalog = Catalog.create!(:tag => "Parent catalog")
    catalog.subcatalogs.create!(:tag => "Catalog1")
    catalog.subcatalogs.create!(:tag => "Catalog2")
    within("#container_documents form") do
      page.should have_content("Catalog")
      page.should have_content("Name")
      page.should have_xpath(".//fieldset//input[@value='Choose']")
      find("#estimate_catalog")[:disabled].should eq("true")
      find("#estimate_catalog_date")[:disabled].should eq("true")
    end
    find(:xpath, "//fieldset//input[@value='Choose']").click
    page.should have_xpath("//div[@class='form_choose']")
    page.should_not have_selector("input[@value='Save']")
    page.should_not have_selector("input[@value='Draft']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Previous']")
    page.find(:xpath, "//input[@value='Previous']")[:disabled].should eq("true")
    within(:xpath, "//div[@class='form_choose']") do
      page.should have_content(catalog.tag)
      catalog.subcatalogs.each do |item|
        page.should_not have_content(item.tag)
      end
      page.find(:xpath, ".//tr//td[@class='title_choose_item']").click
    end
    page.find(:xpath, "//input[@value='Previous']")[:disabled].should eq("false")
    within(:xpath, "//div[@class='form_choose']") do
      page.should_not have_content(catalog.tag)
      catalog.subcatalogs.each do |item|
        page.should have_content(item.tag)
      end
      page.find(:xpath, ".//tr//td[@class='title_choose_item']").click
      page.should_not have_content(catalog.tag)
      catalog.subcatalogs.each do |item|
        page.should have_content(item.tag)
      end
    end
    page.find(:xpath, "//input[@value='Previous']").click
    page.find(:xpath, "//input[@value='Previous']")[:disabled].should eq("true")
    within(:xpath, "//div[@class='form_choose']") do
      page.should have_content(catalog.tag)
      catalog.subcatalogs.each do |item|
        page.should_not have_content(item.tag)
      end
    end
    page.find(:xpath, "//input[@value='Cancel']").click
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    find(:xpath, "//fieldset//input[@value='Choose']").click
    within(:xpath, "//div[@class='form_choose']") do
      find(:xpath, ".//tr[@id='#{catalog.id}']//td[@class='apply_choose_item']").click
    end
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    find("#estimate_catalog")[:disabled].should eq("true")
    find("#estimate_catalog")[:value].should eq(catalog.tag)
    find("#estimate_catalog_date")[:disabled].should eq("false")

    within("#container_documents form") do
      items = 2.times.collect { Factory(:price_list) }
      items += 5.times.collect { |i| Factory(:price_list, :date => DateTime.now + i) }
      items = items.uniq_by{|i| i.date.strftime("%Y-%m-%d")}.sort_by{|i| i.date}
      catalog.price_lists << items
      fill_in("estimate_catalog_date",
        :with => items[0].date.strftime("%Y-%m-%d")[0..1])
      page.should have_xpath("//div[@class='ac_results' and contains(@style, 'display: block')]")
      within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
        all(:xpath, ".//ul//li").length.should eq(5)
        (0..4).each do |idx|
          page.should have_content(items[idx].date.strftime("%Y-%m-%d"))
        end
        page.should_not have_content(items[5].date.strftime("%Y-%m-%d"))
        all(:xpath, ".//ul//li")[1].click
      end
      find("#estimate_catalog_date")["value"].should eq(items[1].date.strftime("%Y-%m-%d"))
      find(:xpath, "//fieldset//input[@value='Choose']").click
      within(:xpath, "//div[@class='form_choose']") do
        find(:xpath, ".//tr[@id='#{catalog.id}']//td[@class='apply_choose_item']").click
      end
      find("#estimate_catalog_date")["value"].should be_empty
      fill_in("estimate_catalog_date",
        :with => items[0].date.strftime("%Y-%m-%d")[0..1])
      page.should have_xpath("//div[@class='ac_results' and contains(@style, 'display: block')]")
      within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
        all(:xpath, ".//ul//li")[1].click
      end
      find(:xpath, "//fieldset//input[@value='Choose']").click
      find(:xpath, "//input[@value='Cancel']").click
      find("#estimate_catalog_date")["value"].should eq(items[1].date.strftime("%Y-%m-%d"))
    end

    within("#estimate_boms") do
      find("#bom_0")[:disabled].should eq("false")
      find("#count_0")[:disabled].should be_true
      find(:xpath, "//td[@class='estimate-boms-actions']//label").click
      page.has_no_selector?("#bom_0").should be_true
      page.has_no_selector?("#count_0").should be_true
    end
    click_button("Add")
    within("#estimate_boms") do
      items = 6.times.collect { Factory(:bo_m) } .sort_by{|i| i.resource.tag}
      catalog.boms << items
      fill_in("bom_0", :with => items[0].resource.tag[0..1])
      page.should have_xpath(
                      "//div[@class='ac_results' and contains(@style, 'display: block')]")
      within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
        all(:xpath, ".//ul//li").length.should eq(5)
        (0..4).each do |idx|
          page.should have_content(items[idx].resource.tag)
        end
        page.should_not have_content(items[5].resource.tag)
        all(:xpath, ".//ul//li")[1].click
      end
      find("#bom_0")["value"].should eq(items[1].resource.tag)
      find("#tab_0")["value"].should eq(items[1].tab)
      fill_in("count_0", :with => 2)
      # TODO: check update sum
    end
  end
end
