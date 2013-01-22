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
    should validate_presence_of :resource_id
    should validate_presence_of :uid
    should validate_presence_of :bom_type
    should allow_value(Estimate::BoM::BOM, Estimate::BoM::MACHINERY,
                       Estimate::BoM::MATERIALS).for(:bom_type)

    should belong_to(:resource).class_name("::#{Asset.name}")
    should belong_to :catalog
    should have_many(Estimate::BoM.versions_association_name)

    should have_many(:items).class_name(Estimate::BoM).with_foreign_key(:parent_id)
    should have_many(:machinery).class_name(Estimate::BoM).
               with_foreign_key(:parent_id).conditions(bom_type: Estimate::BoM::MACHINERY)
    should have_many(:materials).class_name(Estimate::BoM).
               with_foreign_key(:parent_id).conditions(bom_type: Estimate::BoM::MATERIALS)
    should have_many(:prices)

    should delegate_method(:tag).to(:resource)
    should delegate_method(:mu).to(:resource)
  end

  describe "#create resource" do
    it "should create asset by params" do
      asset = Estimate::BoM.create_resource(tag: "tag33", mu: "mu33")
      asset.should_not be_new_record
      asset.tag.should eq("tag33")
      asset.mu.should eq("mu33")
    end

    it "should find asset by params with case insensitive" do
      asset = create(:asset, tag: "TAG122", mu: "mu222")
      asset2 = Estimate::BoM.create_resource(tag: "tag122", mu: "MU222")
      asset.should eq(asset2)
    end
  end

  describe "#create elements" do
    let(:bom) { create(:bo_m) }

    describe "#build machinery" do
      it "should use asset id" do
        asset = create(:asset)
        bom.build_machinery(uid: "ALSA11", resource_id: asset.id, amount: 10)
        bom.machinery.size.should eq(1)
        mach = bom.machinery.first
        mach.uid.should eq("ALSA11")
        mach.resource.should eq(asset)
        mach.amount.should eq(10)
      end

      it "should create asset by params" do
        bom.machinery.delete_all
        bom.build_machinery(uid: "ALSA112", resource: {tag: "tag", mu: "mu"}, amount: 102)
        bom.machinery.size.should eq(1)
        mach = bom.machinery.first
        mach.uid.should eq("ALSA112")
        mach.resource.should_not be_new_record
        mach.resource.tag.should eq("tag")
        mach.resource.mu.should eq("mu")
        mach.amount.should eq(102)
      end

      it "should find asset by params with case insensitive" do
        bom.machinery.delete_all
        asset = create(:asset, tag: "TAG1", mu: "mu2")
        bom.build_machinery(uid: "ALSA1121", resource: {tag: "tAg1", mu: "MU2"}, amount: 102)
        bom.machinery.size.should eq(1)
        mach = bom.machinery.first
        mach.uid.should eq("ALSA1121")
        mach.resource.should eq(asset)
        mach.amount.should eq(102)
      end
    end

    describe "#build materials" do
      it "should use asset id" do
        asset = create(:asset)
        bom.build_materials(uid: "ALSA", resource_id: asset.id, amount: 10)
        bom.materials.size.should eq(1)
        mat = bom.materials.first
        mat.uid.should eq("ALSA")
        mat.resource.should eq(asset)
        mat.amount.should eq(10)
      end

      it "should create asset by params" do
        bom.materials.delete_all
        bom.build_materials(uid: "ALSA2", resource: {tag: "tag", mu: "mu"}, amount: 102)
        bom.materials.size.should eq(1)
        mat = bom.materials.first
        mat.uid.should eq("ALSA2")
        mat.resource.should_not be_new_record
        mat.resource.tag.should eq("tag")
        mat.resource.mu.should eq("mu")
        mat.amount.should eq(102)
      end

      it "should find asset by params with case insensitive" do
        bom.materials.delete_all
        asset = create(:asset, tag: "TAG11", mu: "mu21")
        bom.build_materials(uid: "ALSA21", resource: {tag: "tAg11", mu: "MU21"}, amount: 102)
        bom.materials.size.should eq(1)
        mat = bom.materials.first
        mat.uid.should eq("ALSA21")
        mat.resource.should eq(asset)
        mat.amount.should eq(102)
      end
    end
  end
end
