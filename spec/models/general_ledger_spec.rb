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
  end

  describe "#paginate" do
    it "should paginate results" do
      GeneralLedger.paginate(page: 1).all.should =~ Txn.limit(Settings.root.per_page).all
      GeneralLedger.paginate(page: 1, per_page: (Txn.count / 2)).all.
          should =~ Txn.limit(Txn.count / 2).all
      GeneralLedger.paginate(page: 2, per_page: (Txn.count / 2)).all.
          should =~ Txn.limit(Txn.count / 2).offset(Txn.count / 2).all
    end
  end

  describe "#on_date" do
    it 'should depend on date' do
      GeneralLedger.on_date(Date.yesterday.to_s).count.should eq(0)
      GeneralLedger.on_date(nil).count.should eq(Txn.count)
      Txn.first.fact.update_attributes!(day: 1.day.since)
      GeneralLedger.on_date(1.day.since.to_s).count.should eq(Txn.count)
      GeneralLedger.on_date(nil).count.should eq(Txn.count - 1)
      GeneralLedger.on_date.count.should eq(Txn.count - 1)
      GeneralLedger.on_date(1.day.since.to_s).all.first.should eq(
        Txn.on_date(1.day.since).first)
    end
  end

  describe '#count' do
    it "should return total count of txns" do
      GeneralLedger.count.should eq(Txn.count)
    end
  end

  describe "#current_scope" do
    it "should return txns paginated" do
      GeneralLedger.paginate(page: 1, per_page: (Txn.count / 2)).all.
                should =~ Txn.limit(Txn.count / 2).all
    end
  end
end
