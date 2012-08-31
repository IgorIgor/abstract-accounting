# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Quote do
  before(:all) do
    @cf = create(:money)
    @c1 = create(:money)
    @c2 = create(:money)
    @y = create(:asset)
    x = create(:asset)
    @a2 = create(:deal,
                  :give => build(:deal_give, :resource => @c2),
                  :take => build(:deal_take, :resource => @c2))
    @dy = create(:deal,
                  :give => build(:deal_give, :resource => @y),
                  :take => build(:deal_take, :resource => @y))
    @bx1 = create(:deal,
                   :give => build(:deal_give, :resource => @c1),
                   :take => build(:deal_take, :resource => x),
                   :rate => (1.0 / 100.0))
    @dx = create(:deal,
                  :give => build(:deal_give, :resource => x),
                  :take => build(:deal_take, :resource => x))
    @sy2 = create(:deal,
                   :give => build(:deal_give, :resource => @y),
                   :take => build(:deal_take, :resource => @c2),
                   :rate => 150.0)
  end

  it "should create quote" do
    q = create(:quote, :money => @c1, :rate => 1.5, :day => DateTime.civil(2008, 3, 24, 12, 0, 0))
    @c1.quote.should eq(q)
  end

  it "should have next behaviour" do
    should validate_presence_of :money_id
    should validate_presence_of :day
    should validate_presence_of :rate
    should validate_presence_of :diff
    should validate_uniqueness_of(:day).scoped_to(:money_id)
    should belong_to :money
    should have_many Quote.versions_association_name
    should have_many(:balances_as_give).through(:money).class_name(Balance)
    should have_many(:balances_as_take).through(:money).class_name(Balance)
  end

  it "should process purchase" do
    fact = create(:fact, :amount => 300.0,
                          :day => DateTime.civil(2008, 3, 24, 12, 0, 0),
                          :from => @bx1, :to => @dx, :resource => @dx.give.resource)
    t = Txn.create!(:fact => fact)
    t.value.should eq(45000.0)
    t.status.should eq(0)
    t.earnings.should eq(0.0)
    Balance.all.count.should eq(2)
    t.from_balance.amount.should eq(30000.0)
    t.from_balance.value.should eq(45000.0)
    t.from_balance.side.should eq(Balance::PASSIVE)
    t.to_balance.amount.should eq(300.0)
    t.to_balance.value.should eq(45000.0)
    t.to_balance.side.should eq(Balance::ACTIVE)
  end

  it "should process rate change before income" do
    Income.all.should be_empty

    q = create(:quote, :money => @c1, :rate => 1.6, :day => DateTime.civil(2008, 3, 25, 12, 0, 0))
    @c1.quote.should eq(q)
    q.diff.should eq(-3000.0)

    Income.all.count.should eq(1)
    Income.open.count.should eq(1)
    Income.open.first.side.should eq(Income::PASSIVE)
    Income.open.first.value.should eq(q.diff)
  end

  it "should process sale advance" do
    @c2.quote.should be_nil
    create(:quote, :money => @c2, :rate => 2.0, :day => DateTime.civil(2008, 3, 25, 12, 0, 0))

    fact = create(:fact, :amount => 60000.0,
                          :day => DateTime.civil(2008, 3, 25, 12, 0, 0),
                          :from => @sy2, :to => @a2, :resource => @a2.give.resource)
    t = Txn.create!(:fact => fact)
    t.value.should eq(120000.0)
    t.status.should eq(0)
    t.earnings.should eq(0.0)
    t.from_balance.amount.should eq(400.0)
    t.from_balance.value.should eq(120000.0)
    t.from_balance.side.should eq(Balance::PASSIVE)
    t.to_balance.amount.should eq(60000.0)
    t.to_balance.value.should eq(120000.0)
    t.to_balance.side.should eq(Balance::ACTIVE)
  end

  it "should process forex sale" do
    create(:quote, :money => @cf, :rate => 1.0, :day => DateTime.civil(2008, 3, 24, 12, 0, 0))
    f1 = create(:deal,
                 :give => build(:deal_give, :resource => @c2),
                 :take => build(:deal_take, :resource => @cf),
                 :rate => 2.1)
    t = Txn.create!(:fact => create(:fact, :amount => 10000.0,
                                        :day => DateTime.civil(2008, 3, 25, 12, 0, 0),
                                        :from => @a2, :to => f1,
                                        :resource => f1.give.resource))
    t.value.should eq(20000.0)
    t.status.should eq(1)
    t.earnings.should eq(1000.0)
    t.from_balance.amount.should eq(50000.0)
    t.from_balance.value.should eq(100000.0)
    t.from_balance.side.should eq(Balance::ACTIVE)
    t.to_balance.amount.should eq(21000.0)
    t.to_balance.value.should eq(21000.0)
    t.to_balance.side.should eq(Balance::ACTIVE)

    f2 = create(:deal,
                 :give => build(:deal_give, :resource => @c2),
                 :take => build(:deal_take, :resource => @cf),
                 :rate => 2.0)
    fact = create(:fact, :amount => 10000.0,
                          :day => DateTime.civil(2008, 3, 25, 12, 0, 0),
                          :from => @a2, :to => f2, :resource => f2.give.resource)
    t = Txn.create!(:fact => fact)
    t.value.should eq(20000.0)
    t.status.should eq(0)
    t.earnings.should eq(0.0)
    t.from_balance.amount.should eq(40000.0)
    t.from_balance.value.should eq(80000.0)
    t.from_balance.side.should eq(Balance::ACTIVE)
    t.to_balance.amount.should eq(20000.0)
    t.to_balance.value.should eq(20000.0)
    t.to_balance.side.should eq(Balance::ACTIVE)

    f3 = create(:deal,
                 :give => build(:deal_give, :resource => @c2),
                 :take => build(:deal_take, :resource => @cf),
                 :rate => 1.95)
    fact = create(:fact, :amount => 10000.0,
                          :day => DateTime.civil(2008, 3, 25, 12, 0, 0),
                          :from => @a2, :to => f3, :resource => f3.give.resource)
    t = Txn.create!(:fact => fact)
    t.value.should eq(20000.0)
    t.status.should eq(1)
    t.earnings.should eq(-500.0)
    t.from_balance.amount.should eq(30000.0)
    t.from_balance.value.should eq(60000.0)
    t.from_balance.side.should eq(Balance::ACTIVE)
    t.to_balance.amount.should eq(19500.0)
    t.to_balance.value.should eq(19500.0)
    t.to_balance.side.should eq(Balance::ACTIVE)
  end

  it "should process rate change" do
    Income.all.count.should eq(1)
    income = Income.new Income.first.attributes

    q = create(:quote, :money => @c2, :rate => 2.1, :day => DateTime.civil(2008, 3, 31, 12, 0, 0))
    @c2.quote.should eq(q)
    q.diff.should eq(3000.0)

    Income.all.count.should eq(2)
    Income.first.start.should eq(income.start)
    Income.first.value.should eq(income.value)
    Income.first.side.should eq(income.side)
    Income.first.paid.should eq(DateTime.civil(2008, 3, 31, 12, 0, 0))
    Income.open.count.should eq(1)
    Income.open.first.side.should eq(Income::PASSIVE)
    Income.open.first.value.should eq(500.0)
  end

  it "should process forex sale after rate change" do
    f4 = create(:deal,
                 :give => build(:deal_give, :resource => @c2),
                 :take => build(:deal_take, :resource => @c1),
                 :rate => (2.1 / 1.6))
    t = Txn.create!(:fact => create(:fact, :amount => 10000.0,
                                        :day => DateTime.civil(2008, 3, 31, 12, 0, 0),
                                        :from => @a2, :to => f4,
                                        :resource => f4.give.resource))
    t.from_balance.amount.should eq(20000.0)
    t.from_balance.value.should eq(42000.0)
    t.from_balance.side.should eq(Balance::ACTIVE)
    t.to_balance.amount.should eq(13125.0)
    t.to_balance.value.should eq(21000.0)
    t.to_balance.side.should eq(Balance::ACTIVE)
  end

  it "should process transfer rollback" do
    c3 = create(:money)
    by3 = create(:deal,
                  :give => build(:deal_give, :resource => c3),
                  :take => build(:deal_take, :resource => @y),
                  :rate => (1.0 / 200.0))
    create(:quote, :money => c3, :rate => 0.8, :day => DateTime.civil(2008, 4, 14, 12, 0, 0))
    f = create(:fact, :amount => 100.0, :day => DateTime.civil(2008, 4, 11, 12, 0, 0),
                       :from => by3, :to => @dy, :resource => @dy.give.resource)

    Fact.all.count.should eq(7)
    State.open.count.should eq(10)

    f.destroy
    Fact.all.count.should eq(6)
    State.open.count.should eq(8)
  end

  it "should produce transcript" do
    tr = Transcript.new(@a2, DateTime.civil(2008, 3, 25, 12, 0, 0),
      DateTime.civil(2008, 3, 31, 12, 0, 0))
    tr.total_debits_diff.should eq(3000.0)
    tr.total_credits_diff.should eq(0.0)
    tr.total_debits.should eq(60000.0)
    tr.total_credits.should eq(40000.0)
    tr.total_debits_value.should eq(120000.0)
    tr.total_credits_value.should eq(81000.0)

    tr = Transcript.new(@bx1, DateTime.civil(2008, 3, 24, 12, 0, 0),
      DateTime.civil(2008, 3, 31, 12, 0, 0))
    tr.total_debits_diff.should eq(0.0)
    tr.total_credits_diff.should eq(3000.0)
    tr.total_debits.should eq(0.0)
    tr.total_credits.should eq(300.0)
    tr.total_debits_value.should eq(0.0)
    tr.total_credits_value.should eq(45000.0)

    tr = Transcript.new(Deal.income, DateTime.civil(2008, 3, 24, 12, 0, 0),
      DateTime.civil(2008, 3, 31, 12, 0, 0))
    tr.total_debits_diff.should eq(3000.0)
    tr.total_credits_diff.should eq(3000.0)
    tr.total_debits.should eq(0.0)
    tr.total_credits.should eq(0.0)
    tr.total_debits_value.should eq(500.0)
    tr.total_credits_value.should eq(1000.0)
  end

  it "should produce balance sheet" do
    BalanceSheet.all.each do |balance|
      if balance.instance_of?(Balance) && balance.deal_id == @bx1.id
        balance.side.should eq(Balance::PASSIVE)
        balance.deal.should eq(@bx1)
        balance.amount.should eq(30000.0)
        balance.value.should eq(45000.0)
        break
      end
    end
  end
end
