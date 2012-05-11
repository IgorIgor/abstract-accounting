# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe "Bug133" do
  it "should fix bug #133" do
    x = create(:money)
    y = create(:asset)
    a = create(:deal,
                :give => build(:deal_give, :resource => x),
                :take => build(:deal_take, :resource => y),
                :rate => (1.0 / 100.0))
    b = create(:deal,
                :give => build(:deal_give, :resource => y),
                :take => build(:deal_take, :resource => y))
    c = create(:deal,
                :give => build(:deal_give, :resource => y),
                :take => build(:deal_take, :resource => x),
                :rate => 150.0)
    d = create(:deal,
                :give => build(:deal_give, :resource => x),
                :take => build(:deal_take, :resource => x))
    create(:quote, :money => x, :day => DateTime.civil(2008, 2, 26, 12, 0, 0))
    Txn.create!(:fact => create(:fact, :amount => 300.0,
                  :day => DateTime.civil(2008, 2, 26, 12, 0, 0),
                  :from => a, :to => b, :resource => a.take.resource))
    Txn.create!(:fact => create(:fact, :amount => 200.0,
                  :day => DateTime.civil(2008, 2, 26, 12, 0, 0),
                  :from => b, :to => c, :resource => b.take.resource))
    Txn.create!(:fact => create(:fact, :amount => 20000.0, :from => c, :to => d,
                  :resource => c.take.resource))
    b = c.balance
    b.should_not be_nil, "Balance is nil"

    b.amount.should eq(10000.0), "Wrong balance amount"
    b.value.should eq(10000.0), "Wrong balance value"
    b.side.should eq(Balance::ACTIVE), "Wrong balance side"
  end
end
