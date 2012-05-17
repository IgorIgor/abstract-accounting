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

  def check_autocomplete(element_id, items, attr)
    fill_in(element_id, :with => "qqqqq")
    page.find("##{element_id}").find(:xpath, ".//..").click
    find("##{element_id}")["value"].should eq("qqqqq")
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
      all(:xpath, ".//li//a")[1].click
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
end

RSpec.configure do |config|
  config.include(ControllerMacros)
end
