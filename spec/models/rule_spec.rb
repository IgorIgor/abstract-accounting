# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Rule do
  let(:rub) { create(:chart).currency }

  it "should have next behaviour" do
    should validate_presence_of :deal_id
    should validate_presence_of :to_id
    should validate_presence_of :rate
    should allow_value(true).for(:fact_side)
    should allow_value(false).for(:fact_side)
    should allow_value(true).for(:change_side)
    should allow_value(false).for(:change_side)
    should belong_to :deal
    should belong_to :from
    should belong_to :to
    should have_many Rule.versions_association_name
  end

  it "should have rule workflow" do
    x = create(:asset)
    y = create(:asset)
    keeper = create(:entity)
    shipment = create(:asset)
    supplier = create(:entity)
    purchase_x = create(:deal,
                         :entity => supplier,
                         :give => build(:deal_give, :resource => rub),
                         :take => build(:deal_take, :resource => x),
                         :rate => (1.0 / 100.0))
    purchase_y = create(:deal,
                         :entity => supplier,
                         :give => build(:deal_give, :resource => rub),
                         :take => build(:deal_take, :resource => y),
                         :rate => (1.0 / 150.0))
    storage_x = create(:deal,
                        :entity => keeper,
                        :give => build(:deal_give, :resource => x),
                        :take => build(:deal_take, :resource => x))
    storage_y = create(:deal,
                        :entity => keeper,
                        :give => build(:deal_give, :resource => y),
                        :take => build(:deal_take, :resource => y))
    sale_x = create(:deal,
                     :entity => supplier,
                     :give => build(:deal_give, :resource => x),
                     :take => build(:deal_take, :resource => rub),
                     :rate => 120.0)
    sale_y = create(:deal,
                     :entity => supplier,
                     :give => build(:deal_give, :resource => y),
                     :take => build(:deal_take, :resource => rub),
                     :rate => 160.0)
    f = create(:fact, :amount => 50.0, :day => DateTime.civil(2008, 9, 16, 12, 0, 0),
      :from => purchase_x, :to => storage_x, :resource => purchase_x.take.resource)
    Txn.create!(:fact => f)
    f = create(:fact, :amount => 50.0, :day => DateTime.civil(2008, 9, 16, 12, 0, 0),
      :from => purchase_y, :to => storage_y, :resource => purchase_y.take.resource)
    Txn.create!(:fact => f)
    Balance.not_paid.count.should eq(4), "Wrong open balances count"
    b = purchase_x.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(5000.0), "Wrong balance amount"
    b.value.should eq(5000.0), "Wrong balance value"
    b.side.should eq(Balance::PASSIVE), "Wrong balance side"
    b = purchase_y.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(7500.0), "Wrong balance amount"
    b.value.should eq(7500.0), "Wrong balance value"
    b.side.should eq(Balance::PASSIVE), "Wrong balance side"
    b = storage_x.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(50.0), "Wrong balance amount"
    b.value.should eq(5000.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
    b = storage_y.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(50.0), "Wrong balance amount"
    b.value.should eq(7500.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"

    shipment_deal = create(:deal,
                            :entity => supplier,
                            :give => build(:deal_give, :resource => shipment),
                            :take => build(:deal_take, :resource => shipment),
                            :isOffBalance => true)
    Deal.find(shipment_deal.id).isOffBalance.should be_true,
      "Wrong saved value for is off balance"

    create(:rule, :deal => shipment_deal, :from => storage_x,
      :to => sale_x, :rate => 27.0)
    Rule.count.should eq(1), "Rule count is wrong"
    create(:rule, :deal => shipment_deal, :from => storage_y,
      :to => sale_y, :rate => 42.0)
    Rule.count.should eq(2), "Rule count is wrong"

    f = create(:fact, :day => DateTime.civil(2008, 9, 22, 12, 0, 0),
      :from => nil, :to => shipment_deal, :resource => shipment_deal.give.resource)

    State.open.count.should eq(7), "Wrong open states count"
    s = purchase_x.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq(5000.0), "State amount is wrong"

    s = purchase_y.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq(7500.0), "State amount is wrong"

    s = storage_x.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq(23.0), "State amount is wrong"

    s = storage_y.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq(8.0), "State amount is wrong"

    s = sale_x.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq((120.0 * 27.0).accounting_norm), "State amount is wrong"

    s = sale_y.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq((160.0 * 42.0).accounting_norm), "State amount is wrong"

    s = shipment_deal.state
    s.should_not be_nil, "State is nil"
    s.amount.should eq(1.0), "State amount is wrong"

    Txn.create!(:fact => f)
    Balance.not_paid.count.should eq(6), "Wrong open balances count"

    b = purchase_x.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(5000.0), "Wrong balance amount"
    b.value.should eq(5000.0), "Wrong balance value"
    b.side.should eq(Balance::PASSIVE), "Wrong balance side"
    b = purchase_y.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(7500.0), "Wrong balance amount"
    b.value.should eq(7500.0), "Wrong balance value"
    b.side.should eq(Balance::PASSIVE), "Wrong balance side"
    b = storage_x.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(23.0), "Wrong balance amount"
    b.value.should eq(2300.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
    b = storage_y.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(8.0), "Wrong balance amount"
    b.value.should eq(1200.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
    b = sale_x.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(3240.0), "Wrong balance amount"
    b.value.should eq(3240.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
    b = sale_y.balance
    b.should_not be_nil, "Balance is nil"
    b.amount.should eq(6720.0), "Wrong balance amount"
    b.value.should eq(6720.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
  end

  it "should apply filter" do
    storekeeper = create(:entity)
    sonyvaio = create(:asset)
    svwarehouse = create(:deal,
                          :entity => storekeeper,
                          :give => build(:deal_give, :resource => sonyvaio),
                          :take => build(:deal_take, :resource => sonyvaio))
    buyer = create(:entity)
    svsale = create(:deal,
                     :rate => 80000,
                     :entity => buyer,
                     :give => build(:deal_give, :resource => sonyvaio),
                     :take => build(:deal_take, :resource => rub))

    sbrfbank = create(:entity)
    bankaccount = create(:deal,
                          :entity => sbrfbank,
                          :give => build(:deal_give, :resource => rub),
                          :take => build(:deal_take, :resource => rub))
    equipmentsupl = create(:entity)
    purchase = create(:deal,
                       :entity => equipmentsupl,
                       :rate => 0.0000142857143,
                       :give => build(:deal_give, :resource => rub),
                       :take => build(:deal_take, :resource => sonyvaio))
    create(:rule, :deal => svwarehouse, :from => bankaccount,
      :to => purchase, :rate => (1 / purchase.rate).accounting_norm)

    State.count.should eq(9), "Wrong state count"
    fact = create(:fact, :day => DateTime.civil(2011, 9, 1, 12, 0, 0), :amount => 300,
      :from => purchase, :to => svwarehouse, :resource => svwarehouse.give.resource)
    State.count.should eq(11), "Wrong state count"
    State.open.count.should eq(9), "Wrong open state count"
    state = purchase.state
    state.should be_nil, "Purchase state is not nil"
    state = bankaccount.state
    state.should_not be_nil, "Bankaccount state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq((1 / purchase.rate).accounting_norm * fact.amount),
      "Wrong state amount"
    state = svwarehouse.state
    state.should_not be_nil, "Warehouse bank state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount), "Wrong state amount"

    buyerbank = create(:deal,
                        :entity => sbrfbank,
                        :give => build(:deal_give, :resource => rub),
                        :take => build(:deal_take, :resource => rub))

    create(:rule, :deal => svsale, :from => buyerbank, :to => bankaccount)

    State.open.count.should eq(9), "Wrong open state count"
    create(:fact, :day => DateTime.civil(2011, 9, 2, 12, 0, 0),
      :amount => 300, :from => purchase, :to => svsale, :resource => svsale.give.resource)
    State.count.should eq(15), "Wrong state count"
    State.open.count.should eq(12), "Wrong open state count"
    state = purchase.state
    state.should_not be_nil, "Purchase state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq((fact.amount / purchase.rate).accounting_norm),
      "Wrong state amount"
    state = bankaccount.state
    state.should_not be_nil, "Bankaccount state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate - ((1 / purchase.rate).accounting_norm * 300)),
      "Wrong state amount"
    state = svwarehouse.state
    state.should_not be_nil, "Warehouse bank state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount), "Wrong state amount"
    state = buyerbank.state
    state.should_not be_nil, "Buyer bank state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate), "Wrong state amount"
    state = svsale.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate), "Wrong state amount"

    svsale2 = create(:deal,
                      :rate => 70000,
                      :entity => buyer,
                      :give => build(:deal_give, :resource => sonyvaio),
                      :take => build(:deal_take, :resource => rub))

    create(:rule, :deal => purchase, :from => svsale2, :to => bankaccount,
      :fact_side => true)

    State.open.count.should eq(12), "Wrong open state count"
    create(:fact, :day => DateTime.civil(2011, 9, 2, 12, 0, 0),
      :amount => 300, :from => purchase, :to => svsale2, :resource => svsale2.give.resource)
    State.open.count.should eq(12), "Wrong open state count"
    assert_equal 12, State.open.count, "Wrong state count"
    state = purchase.state
    state.should_not be_nil, "Purchase state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(2 * (fact.amount / purchase.rate).accounting_norm),
      "Wrong state amount"
    state = bankaccount.state
    state.should_not be_nil, "Bankaccount state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate), "Wrong state amount"
    state = svwarehouse.state
    state.should_not be_nil, "Warehouse bank state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount), "Wrong state amount"
    state = buyerbank.state
    state.should_not be_nil, "Buyer bank state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate), "Wrong state amount"
    state = svsale.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount * svsale.rate), "Wrong state amount"
    state = svsale2.state
    state.should be_nil, "Sale state is not nil"

    galaxy = create(:asset)
    purchase_g = create(:deal,
                         :entity => equipmentsupl,
                         :rate => 0.0002,
                         :give => build(:deal_give, :resource => rub),
                         :take => build(:deal_take, :resource => galaxy))
    sale_g = create(:deal,
                     :rate => 5000,
                     :entity => buyer,
                     :give => build(:deal_give, :resource => galaxy),
                     :take => build(:deal_take, :resource => rub))

    create(:fact, :day => DateTime.civil(2011, 9, 3, 12, 0, 0),
      :amount => 300, :from => purchase_g, :to => sale_g, :resource => sale_g.give.resource)
    state = purchase_g.state
    state.should_not be_nil, "Buyer bank state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(fact.amount / purchase_g.rate), "Wrong state amount"
    state = sale_g.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(fact.amount * sale_g.rate), "Wrong state amount"

    create(:rule, :deal => sale_g, :from => bankaccount, :to => purchase_g,
      :fact_side => true, :rate => 5000.0)

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0), :amount => sale_g.rate * 200,
      :from => sale_g, :to => bankaccount, :resource => bankaccount.give.resource)
    state = purchase_g.state
    state.should_not be_nil, "Buyer bank state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(300 / purchase_g.rate), "Wrong state amount"
    state = sale_g.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(100 * sale_g.rate), "Wrong state amount"

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0), :amount => sale_g.rate * 200,
      :from => sale_g, :to => bankaccount, :resource => bankaccount.give.resource)
    state = purchase_g.state
    state.should_not be_nil, "Buyer bank state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(200 / purchase_g.rate), "Wrong state amount"
    state = sale_g.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(100), "Wrong state amount"

    nokia = create(:asset)
    purchase_n = create(:deal,
                         :rate => 0.00033,
                         :entity => equipmentsupl,
                         :give => build(:deal_give, :resource => rub),
                         :take => build(:deal_take, :resource => nokia))
    sale_n = create(:deal,
                     :rate => 3000,
                     :entity => buyer,
                     :give => build(:deal_give, :resource => nokia),
                     :take => build(:deal_take, :resource => rub))

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0),
      :amount => (200 / purchase_n.rate).accounting_norm, :from => bankaccount,
      :to => purchase_n, :resource => purchase_n.give.resource)
    state = purchase_n.state
    state.should_not be_nil, "Purchase state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(200.0), "Wrong state amount"

    create(:rule, :deal => purchase_n, :from => sale_n, :to => bankaccount,
      :fact_side => true, :change_side => false, :rate => 3000.0)

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0),
      :amount => 100, :from => purchase_n,
      :to => sale_n, :resource => sale_n.give.resource)
    state = purchase_n.state
    state.should_not be_nil, "Purchase state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(100.0), "Wrong state amount"
    state = sale_n.state
    state.should be_nil, "Sale state is not nil"

    nokia33 = create(:asset)
    purchase_n33 = create(:deal,
                           :rate => 0.00025,
                           :entity => equipmentsupl,
                           :give => build(:deal_give, :resource => rub),
                           :take => build(:deal_take, :resource => nokia33))
    sale_n33 = create(:deal,
                       :rate => 4000,
                       :entity => buyer,
                       :give => build(:deal_give, :resource => nokia33),
                       :take => build(:deal_take, :resource => rub))

    create(:rule, :deal => sale_n33, :from => bankaccount, :to => purchase_n33,
      :change_side => false, :rate => 4000.0)

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0),
      :amount => 100, :from => purchase_n33,
      :to => sale_n33, :resource => sale_n33.give.resource)
    state = purchase_n33.state
    state.should_not be_nil, "Purchase state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(100 / purchase_n33.rate), "Wrong state amount"
    state = sale_n33.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::ACTIVE), "Wrong state side"
    state.amount.should eq(100 * sale_n33.rate), "Wrong state amount"

    sale_n33.rules.clear
    create(:rule, :deal => sale_n33, :from => bankaccount, :to => purchase_n33,
      :fact_side => true, :change_side => false)

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0),
      :amount => 200 * sale_n33.rate, :from => sale_n33,
      :to => bankaccount, :resource => sale_n33.take.resource)
    state = purchase_n33.state
    state.should be_nil, "Purchase state is not nil"
    state = sale_n33.state
    state.should_not be_nil, "Sale state is nil"
    state.side.should eq(State::PASSIVE), "Wrong state side"
    state.amount.should eq(100), "Wrong state amount"

    alcatel = create(:asset)
    purchase_a = create(:deal,
                         :rate => 0.0001,
                         :entity => equipmentsupl,
                         :give => build(:deal_give, :resource => rub),
                         :take => build(:deal_take, :resource => alcatel))
    sale_a = create(:deal,
                     :rate => 1000,
                     :entity => buyer,
                     :give => build(:deal_give, :resource => alcatel),
                     :take => build(:deal_take, :resource => rub))

    create(:rule, :deal => purchase_a, :from => bankaccount, :to => purchase_a,
      :fact_side => true)

    create(:rule, :deal => sale_a, :from => sale_a, :to => bankaccount)

    create(:fact, :day => DateTime.civil(2011, 9, 4, 12, 0, 0), :amount => 100,
      :from => purchase_a, :to => sale_a, :resource => sale_a.give.resource)
    state = purchase_a.state
    state.should be_nil, "Purchase state is not nil"
    state = sale_a.state
    state.should be_nil, "Sale state is not nil"
  end
end
