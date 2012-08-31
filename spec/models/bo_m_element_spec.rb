# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe BoMElement do
  it "should have next behaviour" do
    should validate_presence_of :resource_id
    should validate_presence_of :bom_id
    should validate_presence_of :rate
    should belong_to(:resource).class_name(Asset)
    should belong_to(:bom).class_name(BoM)
    should have_many(BoMElement.versions_association_name)
  end

  describe "#to_rule" do
    before(:all) do
      @chart = create(:chart)
      @bom_deal = create(:deal)
      @auto = create(:asset, :tag => "Avtopogruzchik 5t")
      @bom_element = create(:bo_m_element, :resource => @auto, :rate => 0.33)
    end

    it "should create rule" do
      price = create(:price, :resource => @auto, :rate => (74.03 * 4.70))
      lambda {
        @bom_element.to_rule(@bom_deal, create(:place), price, 1)
      }.should change(@bom_deal.rules, :count).by(1)
      rule = @bom_deal.rules.first
      rule.rate.accounting_norm.should eq((0.33 * (74.03 * 4.70)).accounting_norm)
      rule.deal_id.should eq(@bom_deal.id)
      rule.from.rate.should eq(0.33)
      rule.from.give.resource.should eq(@auto)
      rule.from.take.resource.should eq(@chart.currency)
      rule.from.entity.should eq(@bom_deal.entity)
      rule.to.rate.should eq(1.0)
      rule.to.give.resource.should eq(@chart.currency)
      rule.to.take.resource.should eq(@chart.currency)
      rule.to.entity.should eq(@bom_deal.entity)
    end

    it "should use same deal for money storage in rule" do
      resource = create(:asset, :tag => "Rompressory peredvignie")
      price = create(:price, :resource => resource, :rate => (59.76 * 4.70))
      element = create(:bo_m_element, :resource => resource, :rate => 0.46)
      lambda {
        element.to_rule(@bom_deal, create(:place), price, 1)
      }.should change(Deal, :count).by(1)
      rule = @bom_deal.rules.last
      rule.rate.accounting_norm.should eq((0.46 * (59.76 * 4.70)).accounting_norm)
      rule.deal_id.should eq(@bom_deal.id)
      rule.from.rate.should eq(0.46)
      rule.from.give.resource.should eq(resource)
      rule.from.take.resource.should eq(@chart.currency)
      rule.from.entity.should eq(@bom_deal.entity)
      rule.to.should eq(@bom_deal.rules.first.to)
    end

    it "should use same convertation deal" do
      price = create(:price, :resource => @auto, :rate => (78.03 * 4.70))
      lambda {
        @bom_element.to_rule(@bom_deal, create(:place), price, 1)
      }.should change(Deal, :count).by(0)
      rule = @bom_deal.rules.last
      rule.rate.accounting_norm.should eq((0.33 * (78.03 * 4.70)).accounting_norm)
      rule.deal_id.should eq(@bom_deal.id)
      rule.from.should eq(@bom_deal.rules.first.from)
      rule.to.should eq(@bom_deal.rules.first.to)
    end

    it "should multiple amount by physical volume" do
      physical_volume = 2
      price = create(:price, :resource => @auto, :rate => (80.03 * 4.70))
      lambda {
        @bom_element.to_rule(@bom_deal, create(:place), price, physical_volume)
      }.should change(Deal, :count).by(0)
      rule = @bom_deal.rules.last
      rule.rate.accounting_norm.should eq((0.33 * (80.03 * 4.70) * 2).accounting_norm)
      rule.deal_id.should eq(@bom_deal.id)
      rule.from.should eq(@bom_deal.rules.first.from)
      rule.to.should eq(@bom_deal.rules.first.to)
    end
  end
end
