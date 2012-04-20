require "rspec"
require 'spec_helper'

feature "GeneralLedger", %q{
  As an user
  I want to view general ledger
} do

  scenario 'visit general ledger page', js: true do

    rub = Factory(:chart).currency
    aasii = Factory(:asset)
    share2 = Factory(:deal,
                      :give => Factory.build(:deal_give, :resource => aasii),
                      :take => Factory.build(:deal_take, :resource => rub),
                      :rate => 10000.0)
    share1 = Factory(:deal,
                      :give => Factory.build(:deal_give, :resource => aasii),
                      :take => Factory.build(:deal_take, :resource => rub),
                      :rate => 10000.0)
    bank = Factory(:deal,
                    :give => Factory.build(:deal_give, :resource => rub),
                    :take => Factory.build(:deal_take, :resource => rub),
                    :rate => 1.0)
    purchase = Factory(:deal,
                        :give => Factory.build(:deal_give, :resource => rub),
                        :rate => 0.0000142857143)
    fact1 = Factory(:fact, :day => DateTime.civil(2011, 11, 22, 12, 0, 0), :from => share2,
                   :to => bank, :resource => rub, :amount => 100000.0)
    fact2 = Factory(:fact, :day => DateTime.civil(2011, 11, 22, 12, 0, 0), :from => share1,
                   :to => bank, :resource => rub, :amount => 142000.0)
    fact3 = Factory(:fact, :day => DateTime.civil(2011, 11, 23, 12, 0, 0), :from => bank,
                   :to => purchase, :resource => rub, :amount => 70000.0)
    fact4 = Factory(:fact, :day => DateTime.civil(2011, 11, 23, 12, 0, 0), :from => nil,
                   :to => Factory(:deal, isOffBalance: true),
                   :amount => 1.0)
    Txn.create!(:fact => fact1)
    Txn.create!(:fact => fact2)
    Txn.create!(:fact => fact3)
    Txn.create!(:fact => fact4)

    general_ledger = GeneralLedger.all

    page_login

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
        general_ledger.each do |txn|
          page.should have_content(txn.fact.day.strftime('%Y-%m-%d'))
          page.should have_content(txn.fact.amount.to_s)
          page.should have_content(txn.fact.resource.tag)
          page.should have_content(txn.value)
          page.should have_content(txn.earnings)
        end

        general_ledger.count.times do |ind|
          find(:xpath, ".//tr[#{(ind * 2) + 1}]/td[7]").should have_content('')
          find(:xpath, ".//tr[#{(ind * 2) + 2}]/td[6]").should have_content('')
          if general_ledger[ind].fact.from.nil?
            within(:xpath, ".//tr[#{(ind * 2) + 2}]") do
              7.times do |i|
                find(:xpath, ".//td[#{i + 1}]").should have_content('')
              end
            end
          end
        end
      end
    end
  end
end
