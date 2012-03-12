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

  scenario "manage waybills", :js => true do
    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/waybills/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    current_hash.should eq("documents/waybills/new")
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
  end
end
