# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::BoM do
  it "should have next behaviour" do
    should validate_presence_of(:resource_id)
    should validate_presence_of(:uid)
    should belong_to(:resource).class_name("::#{Asset.name}")
    should have_many(Estimate::BoM.versions_association_name)
    should have_many(:items).class_name(Estimate::BoMElement)
    should have_many(:builders).class_name(Estimate::BoMElement)
    should have_many(:rank).class_name(Estimate::BoMElement)
    should have_many(:machinist).class_name(Estimate::BoMElement)
    should have_many(:machinery).class_name(Estimate::BoMElement)
    should have_many(:resources).class_name(Estimate::BoMElement)
    should have_and_belong_to_many(:catalogs)
  end

  describe "#build elements" do
    before :all do
      create :chart
      asset = create :asset
      @bom = Estimate::BoM.new(uid: "123", resource_id: asset.id)
    end

    it 'should create builders and rank elements' do
      @bom.element_builders(150, 250)
      @bom.save.should be_true
      @bom.builders[0].uid.should eq('1')
      @bom.builders[0].element_type.should eq(Estimate::BoM::BUILDERS)
      @bom.builders[0].rate.should eq(150)
      @bom.builders[0].resource.tag.should eq(I18n.t('views.estimates.elements.builders'))
      @bom.builders[0].resource.mu.should eq(I18n.t('views.estimates.elements.mu.people'))
      @bom.rank[0].uid.should eq('1.1')
      @bom.rank[0].element_type.should eq(Estimate::BoM::BUILDERS)
      @bom.rank[0].rate.should eq(250)
      @bom.rank[0].resource.tag.should eq(I18n.t('views.estimates.elements.rank'))
    end

    it 'should create machinist elements' do
      @bom.element_machinist(150)
      @bom.save.should be_true
      @bom.machinist[0].uid.should eq('2')
      @bom.machinist[0].element_type.should eq(Estimate::BoM::MACHINIST)
      @bom.machinist[0].rate.should eq(150)
      @bom.machinist[0].resource.tag.should eq(I18n.t('views.estimates.elements.machinist'))
      @bom.machinist[0].resource.mu.should eq(I18n.t('views.estimates.elements.mu.machine'))
    end

    it 'should create machinery and resources elements' do
      mach = create(:asset, tag: 'auto')
      res = create(:asset, tag: 'hummer', mu: 'sht')
      @bom.element_items({code: '123', rate: 150, tag: mach.tag },Estimate::BoM::MACHINERY)
      @bom.element_items({code: '234', rate: 250, tag: res.tag, mu: res.mu },Estimate::BoM::RESOURCES)
      @bom.save.should be_true
      @bom.machinery[0].uid.should eq('123')
      @bom.machinery[0].element_type.should eq(Estimate::BoM::MACHINERY)
      @bom.machinery[0].rate.should eq(150)
      @bom.machinery[0].resource.tag.should eq(mach.tag)
      @bom.machinery[0].resource.mu.should eq(I18n.t('views.estimates.elements.mu.machine'))
      @bom.resources[0].uid.should eq('234')
      @bom.resources[0].element_type.should eq(Estimate::BoM::RESOURCES)
      @bom.resources[0].rate.should eq(250)
      @bom.resources[0].resource.tag.should eq(res.tag)
      @bom.resources[0].resource.mu.should eq(res.mu)
    end

    it 'should create machinery and resources elements with resource_id' do
      mach = create(:asset, tag: 'auto', mu: I18n.t('views.estimates.elements.mu.machine'))
      res = create(:asset, tag: 'hummer', mu: 'sht')
      @bom.element_items({code: '123', rate: 150, id: mach.id },Estimate::BoM::MACHINERY)
      @bom.element_items({code: '234', rate: 250, id: res.id },Estimate::BoM::RESOURCES)
      @bom.save.should be_true
      @bom.machinery[0].uid.should eq('123')
      @bom.machinery[0].element_type.should eq(Estimate::BoM::MACHINERY)
      @bom.machinery[0].rate.should eq(150)
      @bom.machinery[0].resource.tag.should eq(mach.tag)
      @bom.machinery[0].resource.mu.should eq(I18n.t('views.estimates.elements.mu.machine'))
      @bom.resources[0].uid.should eq('234')
      @bom.resources[0].element_type.should eq(Estimate::BoM::RESOURCES)
      @bom.resources[0].rate.should eq(250)
      @bom.resources[0].resource.tag.should eq(res.tag)
      @bom.resources[0].resource.mu.should eq(res.mu)
    end
  end

  describe "#to_deal" do
    before(:all) do
      create(:chart)
      @entity = create(:entity)
      @truck = create(:asset)
      @compressor = create(:asset)
      @compaction = create(:asset)
      @prices = create(:price_list,
                        :resource => create(:asset,:tag => "TUP of the Leningrad region"),
                        :date => DateTime.civil(2011, 11, 01, 12, 0, 0))
      @prices.items.create!(:resource => @truck, :rate => (74.03 * 4.70))
      @prices.items.create!(:resource => @compressor, :rate => (59.76 * 4.70))
      @bom = create(:bo_m, :resource => @compaction)
      @bom.items.create!(:resource => @truck, :rate => 0.33)
      @bom.items.create!(:resource => @compressor,
                        :rate => 0.46)
    end

    it "should create deal with rules" do
      deal = nil
      lambda {
        deal = @bom.to_deal(@entity, create(:place), @prices, 1)
      }.should change(Deal, :count).by(4)
      deal.should_not be_nil
      deal.entity.should eq(@entity)
      deal.give.resource.should eq(@compaction)
      deal.take.resource.should eq(@compaction)
      deal.rate.should eq(1.00)
      deal.isOffBalance.should be_true
      deal.rules.count.should eq(2)
      [deal.rules.all.first.from.give.resource,
       deal.rules.all.last.from.give.resource].should =~ [@compressor, @truck]
      deal.rules.each do |rule|
        if rule.from.give == @truck
          rule.rate.should eq(0.33 * (74.03 * 4.70))
          rule.from.rate.should eq(0.33)
        elsif rule.from.give == @compressor
          rule.rate.should eq(0.46 * (59.76 * 4.70))
          rule.from.rate.should eq(0.46)
        end
      end
    end

    it "should create different deal for same entity and bom" do
      @bom.to_deal(@entity, create(:place), @prices, 1).should_not be_nil
    end

    it "should resend physical volume to rule creation" do
      deal = @bom.to_deal(@entity, create(:place), @prices, 2)
      deal.rules.count.should eq(2)
      [deal.rules.all.first.from.give.resource,
       deal.rules.all.last.from.give.resource].should =~ [@compressor, @truck]
      deal.rules.each do |rule|
        if rule.from.give == @truck
          rule.rate.should eq(0.33 * (74.03 * 4.70) * 2)
          rule.from.rate.should eq(0.33)
        elsif rule.from.give == @compressor
          rule.rate.should eq(0.46 * (59.76 * 4.70) * 2)
          rule.from.rate.should eq(0.46)
        end
      end
    end
  end

  it "should return sum by bom" do
    truck = create(:asset)
    compressor = create(:asset)
    compaction = create(:asset)
    prices = create(:price_list,
                      :resource => create(:asset,:tag => "TUP of the Leningrad region"),
                      :date => DateTime.civil(2011, 11, 01, 12, 0, 0))
    prices.items.create!(:resource => truck, :rate => (74.03 * 4.70))
    prices.items.create!(:resource => compressor, :rate => (59.76 * 4.70))
    bom = create(:bo_m, :resource => compaction)
    bom.items.create!(:resource => truck, :rate => 0.33)
    bom.items.create!(:resource => compressor,
                      :rate => 0.46)
    bom.sum(prices, 1).accounting_norm.should eq(
      ((0.33 * (74.03 * 4.70)) + (0.46 * (59.76 * 4.70))).accounting_norm)
    bom.sum(prices, 2).accounting_norm.should eq(
      (((0.33 * (74.03 * 4.70)) + (0.46 * (59.76 * 4.70))) * 2).accounting_norm)
    catalog = Estimate::Catalog.create!(tag: "some catalog")
    catalog.price_lists << prices
    bom.sum_by_catalog(catalog, prices.date, 2).accounting_norm.should eq(
           (((0.33 * (74.03 * 4.70)) + (0.46 * (59.76 * 4.70))) * 2).accounting_norm)
  end
end
