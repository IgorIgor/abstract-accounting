# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'warehouses', %q{
  As an user
  I want to view warehouses
} do

  scenario 'view warehouses', js: true do
    Factory(:chart)
    wb = Factory.build(:waybill)
    [0,1].each { |i|
      wb.add_item("resource##{i}", "mu#{i}", 100+i, 10+i)
    }
    wb.save!

    page_login

    page.find('#warehouses a').click
    current_hash.should eq('warehouses')

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content('Place')
        page.should have_content('Tag')
        page.should have_content('Real Amount')
        page.should have_content('Expiration Amount')
        page.should have_content('MU')
      end
      page.should have_selector("tbody[@data-bind='foreach: documents']")
      page.should have_selector('tbody tr', count: 2)
      page.all('tbody tr').each_with_index { |tr, i|
        tr.should have_content(wb.storekeeper_place.tag)
        tr.should have_content("resource##{i}")
        tr.should have_content("mu#{i}")
        tr.should have_content(100+i)
      }
    end
  end
end
