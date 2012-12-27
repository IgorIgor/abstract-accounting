# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

WarehouseForemanReport.class_eval do
  def ==(other)
    return false unless other.instance_of?(WarehouseForemanReport)
    resource == other.resource && amount == other.amount &&
        price == other.price && sum == other.sum
  end
end

describe WarehouseForemanReport do
  before :all do
    create(:chart)
  end

  describe "#foremen" do
    it "should return empty list by unknown warehouse_id" do
      WarehouseForemanReport.foremen(create(:place).id).should be_empty
    end

    it "should return foremen" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true
      end

      foremen = Allocation.all.collect { |al| al.foreman }
      WarehouseForemanReport.foremen(warehouse.id).should =~ foremen
    end

    it "should return foremen by warehouse id" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true
      end

      foremen = Allocation.joins{deal.give}.
          where{deal.give.place_id == warehouse.id}.all.collect { |al| al.foreman }
      WarehouseForemanReport.foremen(warehouse.id).should =~ foremen

      storekeeper = create(:entity)
      warehouse2 = create(:place)
      resource = create(:asset)

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse2)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse2)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true

        foremen = Allocation.joins{deal.give}.
            where{deal.give.place_id == warehouse.id}.all.collect { |al| al.foreman }
        WarehouseForemanReport.foremen(warehouse.id).should =~ foremen

        foremen = Allocation.joins{deal.give}.
            where{deal.give.place_id == warehouse2.id}.all.collect { |al| al.foreman }
        WarehouseForemanReport.foremen(warehouse2.id).should =~ foremen
      end
    end

    it "should return foremen only for applied allocations" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)

      allocations = []
      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true
        allocations << allocation
      end

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true
        allocation.reverse.should be_true
      end

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.cancel.should be_true
      end

      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
      end

      foremen = allocations.collect { |al| al.foreman }
      WarehouseForemanReport.foremen(warehouse.id).should =~ foremen
    end

    it "should return uniq foremen" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)

      foremen = []
      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true

        foremen << allocation.foreman
      end
      foreman = create(:entity)
      foremen << foreman
      3.times do |i|
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.save!
        allocation.apply.should be_true
      end

      WarehouseForemanReport.foremen(warehouse.id).should =~ foremen
    end
  end

  describe "#all" do
    it "should return empty list for unknown warehouse or foreman" do
      WarehouseForemanReport.all(warehouse_id: create(:place).id,
                                 foreman_id: create(:entity).id).should be_empty
      WarehouseForemanReport.count(warehouse_id: create(:place).id,
                                   foreman_id: create(:entity).id).should eq(0)


      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation,
                         storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true

      WarehouseForemanReport.all(warehouse_id: create(:place).id,
                                 foreman_id: create(:entity).id).should be_empty
      WarehouseForemanReport.count(warehouse_id: create(:place).id,
                                   foreman_id: create(:entity).id).should eq(0)

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: create(:entity).id).should be_empty
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                   foreman_id: create(:entity).id).should eq(0)

      storekeeper = create(:entity)
      warehouse = create(:place)
      resource = create(:asset)
      foreman = create(:entity)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation,
                         storekeeper: storekeeper, storekeeper_place: warehouse,
                         foreman: foreman, foreman_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true

      WarehouseForemanReport.all(warehouse_id: create(:place).id,
                                 foreman_id: foreman.id).should be_empty
      WarehouseForemanReport.count(warehouse_id: create(:place).id,
                                 foreman_id: foreman.id).should == 0
    end

    it "should return list of resources" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)

      allocations = []
      3.times do
        resource = create(:asset)
        resource2 = create(:asset)

        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
        waybill.add_item(tag: resource2.tag, mu: resource2.mu, amount: 100, price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu,
                  amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
        allocation.add_item(tag: resource2.tag, mu: resource2.mu, amount: 99)
        allocation.save!
        allocation.apply.should be_true

        allocations << allocation
      end

      resources = allocations.inject([]) do |mem, al|
        al.items.each do |item|
          mem << WarehouseForemanReport.new(resource: item.resource, amount: item.amount,
                                            price: 11.32)
        end
        mem
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)


      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      resources << WarehouseForemanReport.new(resource: resource, amount: 75.75,
                                              price: 11.32)

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)

      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)

      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
        allocation.reverse.should be_true
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)

      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.cancel.should be_true
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)
    end

    it "should filter by start and stop dates" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resources = []
      date = DateTime.current.change(year: 2011)
      start = nil
      stop = nil

      resource = create(:asset)
      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 13.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      date += 10
      start = date
      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      date += 10
      stop = date
      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      resources << WarehouseForemanReport.new(resource: resource, amount: 151.5,
                                              price: 11.32)

      date += 10
      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 4.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 start: start, stop: stop).should =~ resources

      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 start: start, stop: stop).should eq(resources.count)

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 start: start.change(hour: 0),
                                 stop: stop.change(hour: 0)).should =~ resources

      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                   foreman_id: foreman.id,
                                  start: start.change(hour: 0),
                                  stop: stop.change(hour: 0)).should eq(resources.count)
    end

    it "should paginate data" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resources = []

      20.times do |i|
        resource = create(:asset)
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        if i < 10
          allocation = build(:allocation,
                             storekeeper: storekeeper, storekeeper_place: warehouse,
                             foreman: foreman, foreman_place: warehouse)
          allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
          allocation.save!
          allocation.apply.should be_true
        else
          3.times do
            allocation = build(:allocation,
                               storekeeper: storekeeper, storekeeper_place: warehouse,
                               foreman: foreman, foreman_place: warehouse)
            allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
            allocation.save!
            allocation.apply.should be_true
          end
        end

        if i < 10
          resources << WarehouseForemanReport.new(resource: resource, amount: 25.25,
                                                  price: 11.32)
        else
          resources << WarehouseForemanReport.new(resource: resource, amount: 75.75,
                                                  price: 11.32)
        end
      end

      resources_clone = resources.clone

      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                   foreman_id: foreman.id).should eq(resources.count)

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 page: 1, per_page: 10).each do |item|
        resources.delete(item).should_not be_nil
      end
      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 page: "1", per_page: "10").each do |item|
        resources_clone.delete(item).should_not be_nil
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 page: 2, per_page: 10).should =~ resources
      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 page: "2", per_page: "10").should =~ resources
    end

    it "should return list of resources with average price" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resource = create(:asset)

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 10.0, price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      waybill = build(:waybill,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 12.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      resources = [WarehouseForemanReport.new(resource: resource, amount: 75.75,
                    price: (((11.32 * 10.0) + (12.32 * 100.0)) / 110.0).accounting_norm)]

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should =~ resources
      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id).should eq(resources.count)
    end

    it "should filter by dates and get price from last waybill before range" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resources = []
      date = DateTime.current.change(year: 2011)
      start = nil
      stop = nil

      resource = create(:asset)
      waybill = build(:waybill, created: date - 10,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 200.0, price: 3.32)
      waybill.save!
      waybill.apply.should be_true

      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 200.0, price: 13.32)
      waybill.save!
      waybill.apply.should be_true

      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 200.0, price: 1.32)
      waybill.save!

      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 200.0, price: 4.32)
      waybill.save!
      waybill.apply.should be_true
      waybill.reverse.should be_true

      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 200.0, price: 5.32)
      waybill.save!
      waybill.cancel.should be_true

      date += 10
      start = date

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      date += 10
      stop = date

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      resources << WarehouseForemanReport.new(resource: resource, amount: 151.5,
                                              price: 13.32)

      date += 10
      waybill = build(:waybill, created: date,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 4.32)
      waybill.save!
      waybill.apply.should be_true

      3.times do
        allocation = build(:allocation, created: date,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true
      end

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 start: start, stop: stop).should =~ resources

      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 start: start, stop: stop).should eq(resources.count)
    end

    it "should return resources by ids" do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resources = []

      20.times do |i|
        resource = create(:asset)
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true

        if i % 2 == 0
          resources << WarehouseForemanReport.new(resource: resource, amount: 25.25,
                                                  price: 11.32)
        end
      end

      WarehouseForemanReport.count(warehouse_id: warehouse.id,
                                   foreman_id: foreman.id).should eq(20)

      WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                 foreman_id: foreman.id,
                                 resource_ids: resources.collect{ |item| item.resource.id }.join(",")
      ).should =~ resources
    end

    it 'should sort warehouse foreman report' do
      storekeeper = create(:entity)
      warehouse = create(:place)
      foreman = create(:entity)
      resources = []

      20.times do |i|
        resource = create(:asset)
        waybill = build(:waybill,
                        storekeeper: storekeeper, storekeeper_place: warehouse)
        waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.0, price: 11.32)
        waybill.save!
        waybill.apply.should be_true

        allocation = build(:allocation,
                           storekeeper: storekeeper, storekeeper_place: warehouse,
                           foreman: foreman, foreman_place: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 25.25)
        allocation.save!
        allocation.apply.should be_true

        if i % 2 == 0
          resources << WarehouseForemanReport.new(resource: resource, amount: 25.25,
                                                  price: 11.32)
        end
      end

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'tag', type: 'asc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
                                      sort{|a,b| a.resource.tag <=> b.resource.tag}
      wfr.should eq(wfr_test)

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'tag', type: 'desc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
          sort{|a,b| b.resource.tag <=> a.resource.tag}
      wfr.should eq(wfr_test)

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'mu', type: 'asc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
          sort{|a,b| a.resource.mu <=> b.resource.mu}
      wfr.should eq(wfr_test)

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'mu', type: 'desc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
          sort{|a,b| b.resource.mu <=> a.resource.mu}
      wfr.should eq(wfr_test)

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'amount', type: 'asc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
          sort{|a,b| a.amount <=> b.amount}
      wfr.should eq(wfr_test)

      wfr =  WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                        sort: { field: 'amount', type: 'desc'},
                                        foreman_id: foreman.id,
                                        resource_ids: resources.
                                            collect{ |item| item.resource.id }.join(","))
      wfr_test = WarehouseForemanReport.all(warehouse_id: warehouse.id,
                                            foreman_id: foreman.id,
                                            resource_ids: resources.
                                                collect{ |item| item.resource.id }.join(",")).
          sort{|a,b| b.amount <=> a.amount}
      wfr.should eq(wfr_test)
    end
  end
end
