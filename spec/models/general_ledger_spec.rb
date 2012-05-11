# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe GeneralLedger do
  before(:all) do
    rub = create(:chart).currency
    aasii = create(:asset)
    share2 = create(:deal,
                    give: build(:deal_give, resource: aasii),
                    take: build(:deal_take, resource: rub),
                    rate: 10000.0)
    bank = create(:deal,
                  give: build(:deal_give, resource: rub),
                  take: build(:deal_take, resource: rub),
                  rate: 1.0)
    3.times do |ind|
      create(:txn, fact: create(:fact, from: share2,
                         to: bank, resource: rub, amount: 100000.0))
    end
  end

  describe "#all" do
    it "should pass attr to txn all" do
      GeneralLedger.all.count.should eq(Txn.count)
      GeneralLedger.all(limit: 1).count.should eq(1)
    end

    it "should paginate results" do
      GeneralLedger.all(page: 1).should =~ Txn.limit(Settings.root.per_page).all
      GeneralLedger.all(page: 1, per_page: (Txn.count / 2)).
          should =~ Txn.limit(Txn.count / 2).all
      GeneralLedger.all(page: 2, per_page: (Txn.count / 2)).
          should =~ Txn.limit(Txn.count / 2).offset(Txn.count / 2).all
    end
  end

  describe "#count" do
    it "should return total count of txns" do
      GeneralLedger.count.should eq(Txn.count)
    end
  end
end
