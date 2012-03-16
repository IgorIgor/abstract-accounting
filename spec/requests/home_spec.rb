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

  before {
    PaperTrail.enabled = true
    Factory(:chart)
    @data = []
    (0..2).each {
      wb = Factory.build(:waybill)
      wb.add_item('roof', 'm2', 1, 10.0)
      wb.save!
      @data << wb
    }
  }

  after {
    PaperTrail.enabled = false
  }

  scenario "visit home page", :js => true do
    page_login
    visit home_index_path
    current_path.should eq(home_index_path)
    page.should have_content("root@localhost")
    click_on "Logout"

    user = Factory(:user, :password => "somepass")
    page_login(user.email, "somepass")
    page.should have_content(user.entity.tag)
    page.should have_content("Logout")
    page.should have_content("Inbox")
    page.should have_content("Starred")
    page.should have_content("Drafts")
    page.should have_content("Sent")
    page.should have_content("Trash")
    page.should have_content("Archive")

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

    within('#container_documents table tbody') do
      all(:xpath, './/tr').each_with_index {|tr, idx|
        tr.should have_content(@data[idx].class.name)
        tr.should have_content(@data[idx].storekeeper.tag)
        tr.should have_content(@data[idx].versions.first.created_at.strftime('%Y-%m-%d'))
        tr.should have_content(@data[idx].versions.last.created_at.strftime('%Y-%m-%d'))
      }
    end
  end
end
