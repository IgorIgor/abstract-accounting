# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Balance do
  it "should have next behaviour" do
    create(:balance, :side => Balance::ACTIVE)
    should validate_presence_of :amount
    should validate_presence_of :value
    should validate_presence_of :start
    should validate_presence_of :side
    should validate_presence_of :deal_id
    should allow_value(Balance::PASSIVE).for(:side)
    should allow_value(Balance::ACTIVE).for(:side)
    should_not allow_value("some value").for(:side)
    should_not allow_value(22).for(:side)
    should validate_uniqueness_of(:start).scoped_to(:deal_id)
    should belong_to :deal
    should have_many Balance.versions_association_name
    should have_one(:give).through(:deal)
    should have_one(:take).through(:deal)

    10.times { create(:balance, :side => Balance::PASSIVE) }
    5.times { create(:balance, :side => Balance::ACTIVE) }
    Balance.passive.count.should eq(10)
    Balance.active.count.should eq(6)
    Balance.passive.each { |b| b.side.should eq(Balance::PASSIVE) }
    Balance.active.each { |b| b.side.should eq(Balance::ACTIVE) }
  end

  it "should filter by resource" do
    6.times do |i|
      create(:balance, side: i % 2 == 0 ? Balance::PASSIVE : Balance::ACTIVE, deal:
          create(:deal, give:
              build(:deal_give, resource: Asset.find_or_create_by_tag("asset#{i}")),
                        take:
              build(:deal_take, resource: Asset.find_or_create_by_tag("asset#{5 - i}"))))
    end
    Balance.joins(:give).joins(:take).
        with_resources([{'id' => Asset.find_by_tag("asset0").id, 'type' => Asset.name}]).count.should eq(2)
    Balance.joins(:give).joins(:take).
        with_resources([{'id' => Asset.find_by_tag("asset1").id, 'type' => Asset.name}]).count.should eq(0)  #passive - give, active - take
  end

  it "should filter by entity" do
    3.times do |i|
      create(:balance, deal: create(:deal, entity:
          Entity.find_or_create_by_tag("entity#{i == 2 ? 0 : i}")))
    end
    Balance.joins(:deal).with_entities([{'id' => Entity.find_by_tag("entity0").id.to_s, 'type' => Entity.name}]).
        count.should eq(2)
  end

  it "should filter by place" do
    6.times do |i|
      create(:balance, side: i % 2 == 0 ? Balance::PASSIVE : Balance::ACTIVE, deal:
          create(:deal, give:
              build(:deal_give, place: Place.find_or_create_by_tag("place#{i}")),
                        take:
              build(:deal_take, place: Place.find_or_create_by_tag("place#{5 - i}"))))
    end
    Balance.joins(:give).joins(:take).
        with_places(Place.find_by_tag("place0").id).count.should eq(2)
    Balance.joins(:give).joins(:take).
        with_places(Place.find_by_tag("place1").id).count.should eq(0)
  end
end
