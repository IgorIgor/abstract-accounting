# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module ControllerMacros
  def page_login email = "root@localhost",
                 password = Settings.root.password,
                 remember = false
    visit login_path
    fill_in("email", :with => email)
    fill_in("password", :with => password)

    check('remember_me') if remember
    click_on I18n.t('views.user_sessions.login')
  end

  def current_hash
    current_url.split("#")[1]
  end

  def check_autocomplete(element_id, items, attr, clear = false)
    fill_in(element_id, :with => "qqqqq")
    if !clear
      page.find("##{element_id}").find(:xpath, ".//..").click
      find("##{element_id}")["value"].should eq("qqqqq")
    else
      page.has_css?("##{element_id}", value: '').should be_true
    end
    fill_in(element_id, :with => items[0].send(attr)[0..1])
    page.should have_xpath(
      "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]")
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and " +
                   "contains(@style, 'display: block')]") do
      all(:xpath, ".//li").length.should eq(items.count > 5 ? 5 : items.count)
      items.each_with_index do |item, idx|
        page.should have_content(item.send(attr)) if idx < 5
        page.should_not have_content(item.send(attr)) if idx >= 5
      end
      find(:xpath, ".//li//a[contains(.//text(), '#{items[1].send(attr)}')]").click
    end
    find("##{element_id}")["value"].should eq(items[1].send(attr))
    yield(items[1]) if block_given?
    fill_in(element_id, :with => "")
    find("##{element_id}")["value"].should eq("")
    fill_in(element_id, :with => items[0].send(attr)[0..1])
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[1].click
    end
  end

  def fill_in_autocomplete(element_id, value)
    fill_in(element_id, with: value)
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete') and
                         contains(@style, 'display: block')]") do
      all(:xpath, './/li//a')[0].click
    end
  end

  def check_header(table_selector, items)
    wait_for_ajax
    within(table_selector) do
      within('thead tr') do
        items.each do |item|
          #page.has_content?(item).should eq(true)
          page.should have_content(item)
        end
      end
    end
  end

  def check_content(table_selector, items, count_per_item = 1)
    wait_for_ajax
    within(table_selector) do
      within('tbody') do
        page.should have_selector('tr', count: count_per_item * items.count, visible: true)
        items.each_with_index do |item, i|
          count_per_item.times do |idx|
            within(:xpath, ".//tr[#{i * count_per_item + idx + 1}]") do
              content = yield(item, i * count_per_item + idx)
              content.each do |field|
                page.should have_content(field)
              end
            end
          end
        end
      end
    end
  end

  def check_group_content(table_selector, items)
    within(table_selector) do
      within('tbody') do
        page.should have_selector('tr', count: items.count, visible: true)
        items.each_with_index do |item, i|
          within(:xpath, ".//tr[#{i * 2 + 1}]") do
            content = yield(item)
            content.each do |field|
              page.should have_content(field)
            end
          end
        end
      end
    end
  end

  def check_paginate(paginate_selector, count_all, per_page)
    within(paginate_selector) do
      if count_all < per_page
        per_page = count_all
      end
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find("span[@data-bind='text: count']").should have_content(count_all.to_s)

      find_button('<')[:disabled].should eq('true')
      if count_all > per_page
        find_button('>')[:disabled].should be_nil
      else
        find_button('>')[:disabled].should eq('true')
      end

      if count_all > per_page
        click_button('>')

        to_range = count_all > (per_page * 2) ? per_page * 2 : count_all

        find("span[@data-bind='text: range']").
            should have_content("#{per_page + 1}-#{to_range}")

        find("span[@data-bind='text: count']").
            should have_content(count_all.to_s)

        find_button('<')[:disabled].should be_nil
        click_button('<')

        find("span[@data-bind='text: range']").
            should have_content("1-#{per_page}")

        find_button('<')[:disabled].should eq('true')
        find_button('>')[:disabled].should be_nil
      end
    end
  end

  def next_page(paginate_selector)
    within(paginate_selector) do
      click_button_and_wait('>')
    end
  end

  def prev_page(paginate_selector)
    within(paginate_selector) do
      click_button_and_wait('<')
    end
  end
end

RSpec.configure do |config|
  config.include(ControllerMacros)
end
