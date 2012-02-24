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
    page_login
    click_button("Create")
    current_hash.should eq("documents/estimates/new")
    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    page.find("#inbox")[:class].should_not eq("sidebar-selected")

    within("#container_documents form") do
      items = 6.times.collect { Factory(:legal_entity) } .sort
      fill_in("estimate_entity", :with => items[0].name[0..1])
      page.should have_xpath(
                      "//div[@class='ac_results' and contains(@style, 'display: block')]")
      within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
        all(:xpath, ".//ul//li").length.should eq(5)
        (0..4).each do |idx|
          page.should have_content(items[idx].name)
        end
        page.should_not have_content(items[5].name)
        all(:xpath, ".//ul//li")[1].click
      end
      find("#estimate_entity")["value"].should eq(items[1].name)
      find("#estimate_ident_name")["value"].should eq(items[1].identifier_name)
      find("#estimate_ident_value")["value"].should eq(items[1].identifier_value)
      fill_in("estimate_entity", :with => "")
      find("#estimate_entity")["value"].should eq("")
      find("#estimate_ident_name")["value"].should eq("")
      find("#estimate_ident_value")["value"].should eq("")
      fill_in("estimate_entity", :with => items[0].name[0..1])
      within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
        all(:xpath, ".//ul//li")[1].click
      end
    end
  end
end
