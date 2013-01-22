# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::PriceList do
  it "should have next behaviour" do
    should validate_presence_of :date
    #should validate_uniqueness_of :date, :scope =>  [:bo_m_id, :catalog_id]
    should have_many(Estimate::PriceList.versions_association_name)
    should have_many(:items).class_name(Estimate::Price)
    should belong_to(:catalog)
    should belong_to(:bo_m).class_name(Estimate::BoM)
  end

  describe "#items" do
    before :all do
      create :chart
      asset = create :asset
      @bom = Estimate::BoM.new(uid: "123", resource_id: asset.id)
      @bom.element_builders(150, 250)
      @bom.element_machinist(150)
      mach = create(:asset, tag: 'auto', mu: I18n.t('views.estimates.elements.mu.machine'))
      res = create(:asset, tag: 'hummer', mu: 'sht')
      @bom.element_items({code: '123', rate: 150, id: mach.id },Estimate::BoM::MACHINERY)
      @bom.element_items({code: '234', rate: 250, id: res.id },Estimate::BoM::RESOURCES)
      @bom.save.should be_true
      @price_list = Estimate::PriceList.new(bo_m_id: @bom.id, date: DateTime.now)
    end

    it 'should build items' do
      elements = {
          builders: {rate: '111', bo_m_element_id: @bom.builders[0].id},
          machinist:{rate: '222', bo_m_element_id: @bom.machinist[0].id},
          machinery:[[{}, :bo_m_element => {price_rate: '333', id: @bom.machinery[0].id}]],
          resources:[[{}, :bo_m_element => {price_rate: '444', id: @bom.resources[0].id}]]
      }
      @price_list.build_items(elements)
      @price_list.save.should be_true
      b = @price_list.items.joins{:bo_m_element}.
                      where{bo_m_element.element_type == Estimate::BoM::BUILDERS}
      b_test= @price_list.item_by_element_type(Estimate::BoM::BUILDERS)
      b[0].should eq(b_test[0])
      b[0].bo_m_element_id.should eq(@bom.builders[0].id)
      b[0].rate.should eq(111)

      m = @price_list.items.joins{:bo_m_element}.
                      where{bo_m_element.element_type == Estimate::BoM::MACHINIST}
      m_test= @price_list.item_by_element_type(Estimate::BoM::MACHINIST)
      m[0].should eq(m_test[0])
      m[0].bo_m_element_id.should eq(@bom.machinist[0].id)
      m[0].rate.should eq(222)

      mach = @price_list.items.joins{:bo_m_element}.
                      where{bo_m_element.element_type == Estimate::BoM::MACHINERY}
      mach_test= @price_list.item_by_element_type(Estimate::BoM::MACHINERY)
      mach[0].should eq(mach_test[0])
      mach[0].bo_m_element_id.should eq(@bom.machinery[0].id)
      mach[0].rate.should eq(333)

      res = @price_list.items.joins{:bo_m_element}.
                      where{bo_m_element.element_type == Estimate::BoM::RESOURCES}
      res_test= @price_list.item_by_element_type(Estimate::BoM::RESOURCES)
      res[0].should eq(res_test[0])
      res[0].bo_m_element_id.should eq(@bom.resources[0].id)
      res[0].rate.should eq(444)
    end

    it 'should filing items'do
      machinery = @price_list.item_by_element_type(Estimate::BoM::MACHINERY)
      array = Estimate::PriceList.filing_items(machinery)
      array.should eq([{bo_m_element:{id: machinery[0].bo_m_element.id,
                                      uid: machinery[0].bo_m_element.uid,
                                      rate: machinery[0].bo_m_element.rate,
                                      resource_tag: machinery[0].bo_m_element.resource.tag,
                                      resource_mu: machinery[0].bo_m_element.resource.mu,
                                      price_rate: machinery[0].rate}
                       }])
    end
  end
end
