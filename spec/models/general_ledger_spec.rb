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

  describe "#scope" do
    it "should define instance method" do
      str = "Test string"
      GeneralLedger.class_eval do
        scope :test1 do
          str
        end
      end
      GeneralLedger.new.test1.should eq(str)
    end
    it "should define singleton method" do
      str = "Test string"
      GeneralLedger.class_eval do
        scope :test2 do
          str
        end
      end
      GeneralLedger.test2.should eq(str)
    end
    it "should pass args from singleton to instance methods" do
      GeneralLedger.class_eval do
        scope :test3 do |i|
          i * 2
        end
        scope :test4 do |i, l|
          i * l
        end
      end
      GeneralLedger.test3(5).should eq(10)
      GeneralLedger.test4(3, 4).should eq(12)
    end

    it "should call scoped method in txn scope" do
      GeneralLedger.class_eval do
        scope :test_count do
          count
        end
      end
      GeneralLedger.test_count.should eq(Txn.count)
    end

    it "should return self if scope updated" do
      GeneralLedger.class_eval do
        scope :test_limit do |*args|
          limit(*args)
        end
        scope :test_all do
          all
        end
      end
      GeneralLedger.test_limit(1).class.name.should eq(GeneralLedger.name)
      GeneralLedger.test_limit(1).test_all.count.should eq(1)
    end

    it "should clone self if scope updated" do
      GeneralLedger.class_eval do
        scope :test_by_facts do |ids|
          where { fact_id.in(ids) }
        end
        scope :test_limit do |*args|
          limit(*args)
        end
        scope :test_all do
          all
        end
      end
      fact_ids = Fact.limit(2).select(:id)
      scope = GeneralLedger.test_by_facts(fact_ids)
      scope.test_limit(1).test_all.count.should eq(1)
      scope.test_all.count.should eq(2)
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
      GeneralLedger.paginate(page: 1, per_page: Settings.root.per_page).
          all.should =~ Txn.limit(Settings.root.per_page).all
      GeneralLedger.paginate(page: 1, per_page: (Txn.count / 2)).all.
          should =~ Txn.limit(Txn.count / 2).all
      GeneralLedger.paginate(page: 2, per_page: (Txn.count / 2)).all.
          should =~ Txn.limit(Txn.count / 2).offset(Txn.count / 2).all
    end
  end

  describe "#on_date" do
    it 'should depend on date' do
      GeneralLedger.on_date(Date.yesterday.to_s).
          count.should eq(Txn.on_date(Date.parse(Date.yesterday.to_s)).count)
      GeneralLedger.on_date(nil).count.should eq(Txn.count)
      Fact.first.update_attributes!(day: (Date.today + 3))
      GeneralLedger.on_date((Date.today + 3).to_s).count.should eq(Txn.count)
      GeneralLedger.on_date(nil).count.should eq(Txn.count - 1)
      GeneralLedger.on_date.count.should eq(Txn.count - 1)
      GeneralLedger.on_date((Date.today + 3).to_s).all.first.should eq(
        Txn.on_date((Date.today + 3)).all.first)
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

  describe "#by_deal" do
    it "should filter txns" do
      wb = build(:waybill)
      wb.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
      wb.save!
      wb.apply
      GeneralLedger.by_deal(wb.deal_id).all.should eq(GeneralLedger.by_deals([wb.deal_id]).all)
      GeneralLedger.by_deal(wb.deal_id).all.should =~ Txn.all[-2, 2]
    end
  end

  describe "#app_utils" do
    before :all do
      3.times do |ind|
        rub = create(:money)
        aasii = create(:asset)
        create(:quote, money: rub)
        share2 = create(:deal,
                        give: build(:deal_give, resource: aasii),
                        take: build(:deal_take, resource: rub),
                        rate: 10000.0)
        bank = create(:deal,
                      give: build(:deal_give, resource: rub),
                      take: build(:deal_take, resource: rub),
                      rate: 1.0)
        create(:txn, fact: create(:fact, from: share2,
                     to: bank, resource: rub, amount: 100000.0))
      end
    end

    it "should proxy filtrate method to Txn" do
      GeneralLedger.filtrate(sort: { field: "resource", type: "desc" }).
          all.should eq(Txn.sort_by_resource("desc"))
    end

    it "should proxy sort method to Txn" do
      GeneralLedger.sort({ field: "resource", type: "desc" }).
          all.should eq(Txn.sort_by_resource("desc"))
    end
  end

  describe "#by_deals" do
    it "should filter txns" do
      wb = build(:waybill)
      wb.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
      wb.save!
      wb.apply
      deal_ids = Txn.limit(Txn.count / 2).collect do |item|
        (item.fact_id % 2) == 0 ? item.fact.from_deal_id : item.fact.to_deal_id
      end
      fact_ids = Fact.where{from_deal_id.in(deal_ids) | to_deal_id.in(deal_ids)}.select(:id)
      child_fact_ids = Fact.where{parent_id.in(fact_ids)}.select(:id)
      GeneralLedger.by_deals(deal_ids).all.should eq(Txn.joins{fact}.
          where{fact.id.in(child_fact_ids + fact_ids)})
    end
  end
end
