# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'distributions', %q{
  As an user
  I want to view distributions
} do

  scenario 'view distributions', js: true do
    Factory(:chart)
    wb = Factory.build(:waybill)
    (0..4).each { |i|
      wb.add_item("resource##{i}", "mu#{i}", 100+i, 10+i)
    }
    wb.save!

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/distributions/new']").click
    current_hash.should eq('documents/distributions/new')

    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    page.should have_xpath("//div[@id='ui-datepicker-div']")
    page.find("#created").click
    page.should have_xpath("//div[@id='ui-datepicker-div' and contains(@style, 'display: block')]")
    page.find("#container_documents").click
    page.should have_xpath("//div[@id='ui-datepicker-div' and contains(@style, 'display: none')]")

    page.find("#created").click
    page.find("#ui-datepicker-div table[@class='ui-datepicker-calendar'] tbody tr td a").click

    within("#container_documents form") do
      6.times.collect { Factory(:place) }
      items = Place.find(:all, order: :tag, limit: 5)
      check_autocomplete("storekeeper_place", items, :tag)
      check_autocomplete("foreman_place", items, :tag)

      6.times.collect { Factory(:entity) }
      items = Entity.find(:all, order: :tag, limit: 5)
      check_autocomplete("storekeeper_entity", items, :tag)
      check_autocomplete("foreman_entity", items, :tag)
    end

    within("#container_documents") do
      page.should have_selector("div[@id='resources-tables']")
      within("#resources-tables") do
        page.should have_selector("#available-resources tbody tr")
        within("#available-resources") do
          page.should have_selector('tbody tr', count: 5)
          page.all('tbody tr').each_with_index { |tr, i|
            tr.should have_content("resource##{i}")
            tr.should have_content("mu#{i}")
            tr.should have_content(100+i)
          }
        end

        within("#selected-resources") do
          page.should_not have_selector('tbody tr')
        end

        (0..4).each do |i|
          page.find("#available-resources tbody tr td[@class='distribution-actions'] span").click
          if i < 4 then
            page.should have_selector('#available-resources tbody tr', count: 4-i)
            page.should have_selector('#selected-resources tbody tr', count: 1+i)
          else
            page.should_not have_selector('#available-resources tbody tr')
          end
        end

        within("#available-resources") do
          page.all('tbody tr').each_with_index { |tr, i|
            tr.find("td input[@type='text']")[:value].should eq("#{100+i}")
          }
        end

        (0..4).each do |i|
          page.find("#selected-resources tbody tr td[@class='distribution-actions'] span").click
          if i < 4 then
            page.should have_selector('#selected-resources tbody tr', count: 4-i)
            page.should have_selector('#available-resources tbody tr', count: 1+i)
          else
            page.should_not have_selector('#selected-resources tbody tr')
          end
        end
      end
    end
  end
end
