# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature "user", %q{
  As an user
  I want to create users
}do

  scenario "create users", :js => true do
    page_login

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click
    page.should have_xpath("//ul[@id='documents_list' and contains(@style, 'display: none')]")

    current_hash.should eq('documents/users/new')
    page.should have_selector("div[@id='container_documents'] form")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")
    click_button(I18n.t('views.users.save'))


    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.users.user_name')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.email')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.password')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.password_confirmation')} : #{I18n.t(
            'errors.messages.blank')}")
      end

      6.times { create(:entity) }
      check_autocomplete("user_entity", Entity.order(:tag).limit(5), :tag)

      fill_in('user_entity', with: 'Kingston Jack')
      fill_in('user_email', with: 'wrong mail')
      fill_in('user_password', with: '1234')
      fill_in('user_password_confirmation', with: '123')
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.users.email')} : #{I18n.t('errors.messages.email')}")
        page.should have_content("#{I18n.t('views.users.password')} : #{
            I18n.t(
            'errors.messages.too_short.few', count: 6)}")
        page.should have_content("#{I18n.t('views.users.password_confirmation')} : #{
            I18n.t(
            'errors.messages.equal_to', value: I18n.t('views.users.password'))}")
      end
    end

    fill_in('user_email', with: 'mymail@gmail.com')
    fill_in('user_password', with: '1234567')
    fill_in('user_password_confirmation', with: '1234567')
    find("#container_notification").visible?.should_not be_true

    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(1) && change(Entity, :count).by(1)

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click

    fill_in('user_entity', with: "Kingston")
    page.should have_xpath("//ul[contains(@class, 'ui-autocomplete')"+
                               " and contains(@style, 'display: block')]")
    within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
        " and contains(@style, 'display: block')]") do
      all(:xpath, ".//li//a")[0].click
    end
    fill_in('user_email', with: 'othermail@gmail.com')
    fill_in('user_password', with: '123123123')
    fill_in('user_password_confirmation', with: '123123123')

    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(1) && change(Entity, :count).by(0)

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click
    click_button(I18n.t('views.users.back'))
    page.should have_selector("#inbox[@class='sidebar-selected']")

    page.find('#btn_create').click
    page.find("a[@href='#documents/users/new']").click
    click_button(I18n.t('views.users.add'))
    within("#container_documents form fieldset table tbody") do
      page.should have_selector('tr', count: 1)
      [Waybill.name, Distribution.name].each do |document|
        within(:xpath, ".//tr//select//option[@value='#{document}']") do
          page.should have_content(I18n.t("views.home.#{document.downcase}"))
        end
      end
    end
    click_button(I18n.t('views.users.add'))
    within("#container_documents form fieldset table tbody") do
      page.should have_selector('tr', count: 2)
    end

    click_button(I18n.t('views.users.save'))
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.users.credential')}#0 #{I18n.t(
            'views.users.place')} : #{I18n.t('errors.messages.blank')}")
        page.should have_content("#{I18n.t(
            'views.users.credential')}#1 #{I18n.t(
            'views.users.place')} : #{I18n.t('errors.messages.blank')}")
      end
      place = create(:place)
      within("fieldset table tbody") do
        fill_in("#{I18n.t('views.users.credential')}#0 #{I18n.t(
              'views.users.place')}", with: place.tag)
        fill_in("#{I18n.t('views.users.credential')}#1 #{I18n.t(
            'views.users.place')}", with: place.tag[0..2])
        page.should have_xpath("//ul[contains(@class, 'ui-autocomplete')"+
                                   " and contains(@style, 'display: block')]")
        within(:xpath, "//ul[contains(@class, 'ui-autocomplete')"+
            " and contains(@style, 'display: block')]") do
          all(:xpath, ".//li//a")[0].click
        end
      end
      within("#container_notification ul") do
        find(:xpath, ".//li[contains(.//text(), '#{I18n.t(
            'views.users.credential')}#0 #{I18n.t(
            'views.users.place')} : #{I18n.t('errors.messages.blank')}')]").
            visible?.should_not be_true
        find(:xpath, ".//li[contains(.//text(), '#{I18n.t(
            'views.users.credential')}#1 #{I18n.t(
            'views.users.place')} : #{I18n.t('errors.messages.blank')}')]").
            visible?.should_not be_true
      end
      within("fieldset table tbody") do
        page.find(:xpath, ".//td[@class='table-actions']//label").click
        page.should have_selector('tr', count: 1)
        page.find(:xpath, ".//td[@class='table-actions']//label").click
        page.should_not have_selector('tr')
      end

      fill_in('user_entity', with: 'Some Cool Man')
      fill_in('user_email', with: 'mymail@gmail.com')
      fill_in('user_password', with: '1234567')
      fill_in('user_password_confirmation', with: '1234567')

      click_button(I18n.t('views.users.add'))
      click_button(I18n.t('views.users.add'))
      within("fieldset table tbody") do
        fill_in("#{I18n.t('views.users.credential')}#0 #{I18n.t(
              'views.users.place')}", with: place.tag)
        fill_in("#{I18n.t('views.users.credential')}#1 #{I18n.t(
            'views.users.place')}", with: "Place for creation")
      end
    end
    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(1) && change(Credential, :count).by(2) &&
                   change(Place, :count).by(1)
  end

  scenario "show all users", js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:user) }
    users = User.limit(per_page)
    count = User.count
    page_login
    click_link I18n.t('views.home.users')
    current_hash.should eq('users')
    page.should have_xpath("//div[@id='sidebar']/ul/li[@id='users'" +
                               " and @class='sidebar-selected']")

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.users.email'))
        page.should have_content(I18n.t('views.users.user_name'))
      end

      within('tbody') do
        users.each do |user|
          page.should have_content(user.entity.tag)
          page.should have_content(user.email)
        end
      end
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find("span[@data-bind='text: count']").
          should have_content(count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page)
    end

    within("div[@class='paginate']") do
      click_button('>')

      to_range = count > (per_page * 2) ? per_page * 2 : count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(count.to_s)

      find_button('<')[:disabled].should eq('false')
    end

    users = User.limit(per_page).offset(per_page)
    within('#container_documents table tbody') do
      count_on_page = count - per_page > per_page ? per_page : count - per_page
      page.should have_selector('tr', count: count_on_page)
      users.each do |user|
        page.should have_content(user.entity.tag)
        page.should have_content(user.email)
      end
    end

    within("div[@class='paginate']") do
      click_button('<')

      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end
  end

  scenario "show user", js: true do
    user = User.count > 0 ? User.first : create(:user)
    if user.credentials(:force_update).empty?
      user.credentials.create!(place: create(:place), document_type: Waybill.name)
      user.credentials.create!(place: create(:place), document_type: Distribution.name)
    end
    page_login
    click_link I18n.t('views.home.users')
    current_hash.should eq('users')
    page.should have_xpath("//div[@id='sidebar']/ul/li[@id='users'" +
                               " and @class='sidebar-selected']")
    within('#container_documents table') do
      find(:xpath, ".//tbody//tr[1]//td[contains(.//text(), '#{user.entity.tag}')]").click
    end
    current_hash.should eq("documents/users/#{user.id}")
    find("#user_entity")[:disabled].should eq("true")
    find("#user_email")[:disabled].should eq("true")
    find_button(I18n.t('views.users.add'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")

    find("#user_entity")[:value].should eq(user.entity.tag)
    find("#user_email")[:value].should eq(user.email)


    within("fieldset table tbody") do
      user.credentials(:force_update).each_with_index do |c, i|
        within(:xpath, ".//tr[#{i + 1}]") do
          find(:xpath, ".//td//input[@type='text']")[:value].should eq(c.place.tag)
          find(:xpath, ".//select")[:value].should eq(c.document_type)
          find(:xpath, ".//td//input[@type='text']")[:disabled].should eq("true")
          find(:xpath, ".//td//select")[:disabled].should eq("true")
        end
      end
    end
  end

  scenario "edit user", :js => true do
    user = User.count > 0 ? User.first : create(:user)
    if user.credentials(:force_update).empty?
      user.credentials.create!(place: create(:place), document_type: Waybill.name)
    end
    page_login
    click_link I18n.t('views.home.users')
    current_hash.should eq('users')
    page.should have_xpath("//div[@id='sidebar']/ul/li[@id='users'" +
                               " and @class='sidebar-selected']")
    within('#container_documents') do
      within('table') do
        find(:xpath, ".//tbody//tr[1]//td[contains(.//text(), '#{user.entity.tag}')]").click
      end
      current_hash.should eq("documents/users/#{user.id}")
      find_button(I18n.t('views.users.edit'))[:disabled].should eq('false')

      click_button(I18n.t('views.users.edit'))
      find('#page-title').should have_content(
                                     I18n.t('views.users.page_title_edit'))
      find_button(I18n.t('views.users.edit'))[:disabled].should eq('true')

      find('#user_entity')[:disabled].should eq('false')
      find('#user_email')[:disabled].should eq('false')
      find_button(I18n.t('views.users.add'))[:disabled].should eq('false')

      fill_in('user_entity', with: 'some different entity')
      fill_in('user_email', with: 'some.different@email.ee')

      within("fieldset table tbody") do
        page.should have_selector('tr', count: 1)
        page.find(:xpath, ".//td[@class='table-actions']//label").click
        page.should_not have_selector('tr')
      end

      click_button(I18n.t('views.users.add'))
      within("fieldset table tbody") do
        fill_in("#{I18n.t('views.users.credential')}#0 #{I18n.t(
              'views.users.place')}", with: "Some cool place")
      end
    end

    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(0) && change(Entity, :count).by(1) &&
        change(Credential, :count).by(1)

    Credential.where{place_id == Place.find_by_tag("Some cool place")}.count.should eq(1)

    click_link I18n.t('views.home.users')

    within('#container_documents table tbody') do
      within(:xpath, './/tr[1]') do
        page.should have_content('some different entity')
        page.should have_content('some.different@email.ee')
      end
    end
  end

  scenario "edit user password", js: true do
    password = "password"
    user = User.count > 0 ? User.first : create(:user)
    user.password_confirmation = password
    user.change_password!(password)

    page_login(user.email, password)
    page.should have_selector("#inbox[@class='sidebar-selected']")
    click_link I18n.t('views.home.logout')

    page_login
    click_link I18n.t('views.home.users')
    within('#container_documents') do
      within('table') do
        find(:xpath, ".//tbody//tr[1]//td[contains(.//text(), '#{user.entity.tag}')]").click
      end
      click_button(I18n.t('views.users.edit'))
      find('#user_password')[:disabled].should eq('true')
      find('#user_password_confirmation')[:disabled].should eq('true')
      check('change_pass')
      find('#user_password')[:disabled].should eq('false')
      find('#user_password_confirmation')[:disabled].should eq('false')
      password = 'newpassword'
      fill_in('user_password', with: password)
      fill_in('user_password_confirmation', with: password)
    end
    lambda do
      click_button(I18n.t('views.users.save'))
      page.should have_selector("#inbox[@class='sidebar-selected']")
    end.should change(User, :count).by(0)
    click_link I18n.t('views.home.logout')

    page_login(user.email, password)
    page.should have_selector("#inbox[@class='sidebar-selected']")
    click_link I18n.t('views.home.logout')
  end
end