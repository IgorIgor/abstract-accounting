require "rspec"
require 'spec_helper'

feature "GeneralLedger", %q{
  As an user
  I want to view general ledger
} do

  before :each do
    create(:chart)
  end

  scenario 'visit general ledger page', js: true do
    per_page = Settings.root.per_page
    wb = build(:waybill)
    per_page.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply

    gl = GeneralLedger.paginate(page: 1).all
    gl_count = GeneralLedger.count

    page_login
    page.find('#btn_slide_conditions').click
    click_link I18n.t('views.home.general_ledger')
    current_hash.should eq('general_ledger')

    page.should have_xpath("//li[@id='general_ledger' and @class='sidebar-selected']")

    within('#container_documents table') do
      within('thead tr') do
        page.should have_content(I18n.t('views.general_ledger.date'))
        page.should have_content(I18n.t('views.general_ledger.resource'))
        page.should have_content(I18n.t('views.general_ledger.amount'))
        page.should have_content(I18n.t('views.general_ledger.type'))
        page.should have_content(I18n.t('views.general_ledger.account'))
        page.should have_content(I18n.t('views.general_ledger.price'))
        page.should have_content(I18n.t('views.general_ledger.debit'))
        page.should have_content(I18n.t('views.general_ledger.credit'))
      end

      within('tbody') do
        gl.each do |txn|
          page.should have_content(txn.fact.day.strftime('%Y-%m-%d'))
          page.should have_content(txn.fact.amount.to_s)
          page.should have_content(txn.fact.resource.tag)
          page.should have_content(txn.fact.from.tag)
          page.should have_content(txn.fact.to.tag)
          page.should have_content(txn.value)
          page.should have_content(txn.earnings)
        end

        gl.count.times do |ind|
          find(:xpath, ".//tr[#{(ind * 2) + 1}]/td[7]").should have_content('')
          find(:xpath, ".//tr[#{(ind * 2) + 2}]/td[6]").should have_content('')
          if gl[ind].fact.from.nil?
            within(:xpath, ".//tr[#{(ind * 2) + 2}]") do
              7.times do |i|
                find(:xpath, ".//td[#{i + 1}]").should have_content('')
              end
            end
          end
        end
      end
    end

    within("div[@class='paginate']") do
      find("span[@data-bind='text: range']").should have_content("1-#{per_page}")
      find("span[@data-bind='text: count']").should have_content(gl_count.to_s)

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    within("#container_documents table tbody") do
      page.should have_selector('tr', count: per_page * 2)
    end

    within("div[@class='paginate']") do
      click_button('>')
      to_range = gl_count > (per_page * 2) ? per_page * 2 : gl_count

      find("span[@data-bind='text: range']").
          should have_content("#{per_page + 1}-#{to_range}")

      find("span[@data-bind='text: count']").
          should have_content(gl_count.to_s)

      find_button('<')[:disabled].should eq('false')

      click_button('<')

      find("span[@data-bind='text: range']").
          should have_content("1-#{per_page}")

      find_button('<')[:disabled].should eq('true')
      find_button('>')[:disabled].should eq('false')
    end

    gl.each do |txn|
      txn.fact.update_attributes(day: 1.months.since.change(day: 13))
    end

    page.should have_datepicker("general_ledger_date")
    page.datepicker("general_ledger_date").next_month.day(11)

    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 2)

      page.should have_content(Txn.last.fact.day.strftime('%Y-%m-%d'))
      page.should have_content(Txn.last.fact.amount.to_s)
      page.should have_content(Txn.last.fact.resource.tag)
      page.should have_content(Txn.last.fact.from.tag) unless Txn.last.fact.from.nil?
      page.should have_content(Txn.last.fact.to.tag)
      page.should have_content(Txn.last.value)
      page.should have_content(Txn.last.earnings)
    end
  end

  scenario "go to general ledger page from deals", js: true do
    create(:chart)
    wb = build(:waybill)
    3.times do |i|
      wb.add_item(tag: "resource##{i}", mu: "mu#{i}", amount: 100+i, price: 10+i)
    end
    wb.save!
    wb.apply
    wb2 = build(:waybill)
    3.times do |i|
      wb2.add_item(tag: "resource2##{i}", mu: "mu2#{i}", amount: 200+i, price: 20+i)
    end
    wb2.save!
    wb2.apply

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.deals')
    current_hash.should eq('deals')

    within('#container_documents') do
      page.find(:xpath, ".//table/tbody/tr/td[contains(./text(), '#{wb.deal.tag}')]").click
    end

    date = DateTime.now.strftime('%Y-%m-%d')
    current_hash.should eq("general_ledger?deal_id=#{wb.deal_id}&date=#{date}")

    page.find('#general_ledger_date')[:value].
        should eq(DateTime.now.strftime('%d.%m.%Y'))

    scope = GeneralLedger.on_date(date).paginate(page: 1)
    items = scope.by_deal(wb.deal_id).all
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: items.count * 2)

      items.each do |item|
        page.should have_content(item.fact.day.strftime('%Y-%m-%d'))
        page.should have_content(item.fact.amount.to_s)
        page.should have_content(item.fact.resource.tag)
        page.should have_content(item.fact.from.tag) unless item.fact.from.nil?
        page.should have_content(item.fact.to.tag)
        page.should have_content(item.value)
        page.should have_content(item.earnings)
      end

      scope.by_deal(wb2.deal_id).all.each do |item|
        page.should_not have_content(item.fact.amount.to_s) unless item.fact.from.nil?
        page.should_not have_content(item.fact.from.tag) unless item.fact.from.nil?
        page.should_not have_content(item.fact.to.tag)
        page.should_not have_content(item.value) unless item.fact.from.nil?
      end
    end
  end
end
