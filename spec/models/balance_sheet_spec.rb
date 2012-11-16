# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe BalanceSheet do
  before(:all) do
    4.times { create(:balance) }
  end

  describe "#filter_attr" do
    it "should define instance methods" do
      BalanceSheet.class_eval do
        filter_attr :test
      end
      obj = BalanceSheet.new
      obj.test(12)
      obj.test_value.should eq(12)
    end

    it "should return instance after assign filter value" do
      BalanceSheet.class_eval do
        filter_attr :test
      end
      BalanceSheet.new.test(26).test_value.should eq(26)
    end

    it "should define singleton method" do
      BalanceSheet.class_eval do
        filter_attr :test
      end
      BalanceSheet.test(32).class.name.should eq(BalanceSheet.name)
      BalanceSheet.test(32).test_value.should eq(32)
    end

    it "should pass default option" do
      BalanceSheet.class_eval do
        filter_attr :test, default: 128
      end
      BalanceSheet.test().test_value.should eq(128)
    end
  end

  describe "#getter" do
    it "should define instance method" do
      str = "hello getter"
      BalanceSheet.class_eval do
        getter :test do
          str
        end
      end
      BalanceSheet.new.test.should eq(str)
    end

    it "should define singleton method" do
      str = "hello getter2"
      BalanceSheet.class_eval do
        getter :test do
          str
        end
      end
      BalanceSheet.test.should eq(str)
    end

    it "should pass arguments" do
      BalanceSheet.class_eval do
        getter :test do |i|
          5 + i
        end
      end
      BalanceSheet.test(9).should eq(14)
    end
  end

  describe "#date" do
    it "should have filter attribute" do
      date = 1.day.ago
      BalanceSheet.date(date).date_value.should eq(date)
    end
    it "should set default value" do
      BalanceSheet.date().date_value.to_date().should eq(DateTime.now.to_date())
      BalanceSheet.date(nil).date_value.to_date().should eq(DateTime.now.to_date())
    end
    it "should return default value" do
      BalanceSheet.new.date_value.to_date().should eq(DateTime.now.to_date())
    end
  end

  describe "#paginate" do
    it "should have filter attribute" do
      BalanceSheet.paginate(page: 1, per_page: 10).paginate_value.
          should eq(page: 1, per_page: 10)
    end
  end

  describe "#resource" do
    it "should have filter attribute" do
      BalanceSheet.resource(id: 1, type: Asset.name).resource_value.
          should eq(id: 1, type: Asset.name)
    end
  end

  describe "#entity" do
    it "should have filter attribute" do
      BalanceSheet.entities([{'id' => 1, 'type' => Entity.name}]).entities_value.
          should eq([{'id' => 1, 'type' => Entity.name}])
    end
  end

  describe "#place_id" do
    it "should have filter attribute" do
      BalanceSheet.place_ids(1).place_ids_value.should eq(1)
    end
  end

  describe "#getter" do
    it "should define singleton method" do
      BalanceSheet.class_eval do
        filter_attr :test_value, default: 3
        getter :test_all do
          self.test_value_value + 2
        end
      end
      BalanceSheet.test_all.should eq(5)
    end
    it "should define instance method" do
      BalanceSheet.class_eval do
        filter_attr :test_value, default: 3
        getter :test_all do
          self.test_value_value + 2
        end
      end
      BalanceSheet.test_value(4).test_all.should eq(6)
    end
  end

  describe "#all" do
    it "pass options to find method" do
      BalanceSheet.all(include: [:deal]).each do |balance|
        balance.association(:deal).loaded?.should be_true
      end
    end

    it "should paginate data" do
      BalanceSheet.all.count.should eq(Balance.count)
      BalanceSheet.paginate(page: 1, per_page: 3).all.count.should eq(3)
      BalanceSheet.paginate(page: 2, per_page: 3).all.count.should eq(1)
    end

    it "should paginate balances" do
      entity = create(:entity)
      5.times { create(:balance, deal: create(:deal, entity: entity)) }
      BalanceSheet.entities([{'id' => entity.id.to_s, 'type' => entity.class.name}]).
          paginate(page: 1, per_page: 3).all.count.should eq(3)
      BalanceSheet.entities([{'id' => entity.id.to_s, 'type' => entity.class.name}]).
          paginate(page: 2, per_page: 3).all.count.should eq(2)
    end
  end

  describe "#db_count" do
    it "should return total count of records" do
      BalanceSheet.db_count.should eq(Balance.count)
      BalanceSheet.paginate(page: 1, per_page: 3).db_count.should eq(Balance.count)
    end
  end

  describe "#group_by with  type" do
    it "should have filter attribute" do
      BalanceSheet.group_by('place').db_count.should eq(9)
      BalanceSheet.group_by('entity').db_count.should eq(5)
      BalanceSheet.group_by('resource').db_count.should eq(9)
    end
  end

  describe "#search" do
    it "should have search attribute" do
      BalanceSheet.search(resource: 'res').search_value.should eq(resource: 'res')
    end
  end

  it "should sort balance_sheet" do
    bss =  BalanceSheet.order({field: 'deal', type: 'asc'}).all
    bss_test = Balance.joins{deal.outer}.order("deals.tag asc")
    bss.should eq(bss_test)
    bss =  BalanceSheet.order({field: 'deal', type: 'desc'}).all
    bss_test = Balance.joins{deal.outer}.order("deals.tag desc")
    bss.should eq(bss_test)

    query = "case entity_type
                              when 'Entity'      then entities.tag
                              when 'LegalEntity' then legal_entities.name
                         end"
    bss =  BalanceSheet.order({field: 'entity', type: 'asc'}).all
    bss_test = Balance.joins{deal.entity(Entity).outer}.
                       joins{deal.entity(LegalEntity).outer}.
                       order("#{query} asc")
    bss.should eq(bss_test)
    bss =  BalanceSheet.order({field: 'entity', type: 'desc'}).all
    bss_test = Balance.joins{deal.entity(Entity).outer}.
                       joins{deal.entity(LegalEntity).outer}.
                       order("#{query} desc")
    bss.should eq(bss_test)

    query = "case resource_type
                              when 'Asset' then assets.tag
                              when 'Money' then money.alpha_code
                         end"
    bss =  BalanceSheet.order({field: 'resource', type: 'asc'}).all
    bss_test = Balance.joins{give.resource(Asset).outer}.
                       joins{give.resource(Money).outer}.
                       order("#{query} asc")
    bss.should eq(bss_test)
    bss =  BalanceSheet.order({field: 'resource', type: 'desc'}).all
    bss_test = Balance.joins{give.resource(Asset).outer}.
                       joins{give.resource(Money).outer}.
                       order("#{query} desc")
    bss.should eq(bss_test)

    bss =  BalanceSheet.order({field: 'place', type: 'asc'}).all
    bss_test = Balance.joins{give.place.outer}.
                       joins{give.place.outer}.
                       order("places.tag asc")
    bss.should eq(bss_test)
    bss =  BalanceSheet.order({field: 'place', type: 'desc'}).all
    bss_test = Balance.joins{give.place.outer}.
                       joins{give.place.outer}.
                       order("places.tag desc")
    bss.should eq(bss_test)
  end
end
