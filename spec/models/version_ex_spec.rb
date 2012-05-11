# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe VersionEx do
  before :all do
    PaperTrail.enabled = true
  end

  after :all do
    PaperTrail.enabled = false
  end

  describe '#lasts' do
    let(:entity) { create(:entity) }
    it 'should return one version if object was created' do
      versions = VersionEx.lasts.where(
        "item_type='Entity' AND versions.item_id=#{entity.id}")
      entity.versions.last.id.should eq(versions.first.id)
      versions.count.should eq(1)
    end

    it 'should return last version after object was updated' do
      entity.update_attributes!(tag: 'new_tag')
      entity.versions.count.should eq(2)
      entity.update_attributes!(tag: 'new_tag2')
      entity.versions.count.should eq(3)
      versions = VersionEx.lasts.where(
        "item_type='Entity' AND versions.item_id=#{entity.id}")
      entity.versions.last.id.should eq(versions.first.id)
      versions.count.should eq(1)
    end
  end

  describe '#by_type' do
    it 'should return only objects with special types' do
      types = [Entity.name]
      create(:entity)
      versions = VersionEx.by_type(types)
      versions.each { |version| version.item_type.should eq(types[0]) }
      create(:legal_entity)
      types << LegalEntity.name
      versions = VersionEx.by_type(types)
      versions.any?.should eq(true)
      versions.each do |version|
        (version.item_type == types[0] ||
          version.item_type == types[1]).should eq(true)
      end
    end
  end

  describe '#paginate' do
    it 'should split records by pages' do
      per_page = Settings.root.per_page

      per_page.times { create(:entity) }

      ver1 = VersionEx.paginate()
      ver1.count.should eq(per_page)

      ver2 = VersionEx.paginate({page: 1})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({page: '1'})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({per_page: per_page})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({per_page: per_page.to_s})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({page: 1, per_page: per_page})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({page: '1', per_page: per_page.to_s})
      ver1.should eq(ver2)

      ver2 = VersionEx.paginate({page: 2, per_page: per_page})
      (ver2 & ver1).empty?.should eq(true)
    end
  end

  describe '#filter' do
    it 'should filtered records' do
      create(:chart)
      items = []
      (0..2).each do |i|
        st = create(:entity, tag: "storekeeper#{i}")
        stp = create(:place, tag: "sk_place#{i}")
        ds = create(:legal_entity, name: "ds_name#{i}",
               identifier_name: "ds_id_name#{i}",
               identifier_value: "ds_id_value#{i}")
        dsp = create(:place, tag: "ds_place#{i}")

        wb = build(:waybill, document_id: "test_document_id#{i}",
               storekeeper: st, storekeeper_place: stp, distributor: ds,
               distributor_place: dsp)
        wb.add_item('roof', 'm2', 2, 1.0)
        wb.save!
        items << wb

        fr = create(:entity, tag: "foreman#{i}")
        frp = create(:place, tag: "fr_place#{i}")
        dsn = build(:distribution, storekeeper: st,
                storekeeper_place: stp, foreman: fr, foreman_place: frp)
        dsn.add_item('roof', 'm2', 1)
        dsn.save!
        items << dsn
      end

      st = Entity.find_by_tag('storekeeper1')
      stp = Place.find_by_tag('sk_place1')
      ds = LegalEntity.find_by_name_and_identifier_name_and_identifier_value(
             'ds_name1', 'ds_id_name1', 'ds_id_value1')
      dsp = Place.find_by_tag('ds_place1')
      fr = Entity.find_by_tag('foreman1')
      frp = Place.find_by_tag('fr_place1')

      VersionEx.filter().should eq(VersionEx.all)

      filtered = items.select { |i| i.kind_of?(Waybill) }
      VersionEx.filter(waybill: { created: Date.today.to_s[0,2] })
        .map { |v| v.item } .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.document_id == 'test_document_id1'}
      VersionEx.filter(waybill: { document_id: 'test_document_id1' })
        .map { |v| v.item } .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Waybill) && i.storekeeper == st}
      VersionEx.filter(waybill: {
                        storekeeper: {
                          entity: { tag: 'storekeeper1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.storekeeper_place == stp}
      VersionEx.filter(waybill: {
                        storekeeper_place: {
                          place: { tag: 'sk_place1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Waybill) && i.distributor == ds}
      VersionEx.filter(waybill: {
                        distributor: {
                          legal_entity: {
                            identifier_name: 'ds_id_name1',
                            identifier_value: 'ds_id_value1',
                            name: 'ds_name1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.distributor_place == dsp}
      VersionEx.filter(waybill: {
                        distributor_place: {
                          place: { tag: 'ds_place1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      VersionEx.filter(waybill: { created: Date.today.to_s[0,2] },
                       distribution: { created: Date.today.to_s[0,2] })
        .count.should eq(items.count)

      filtered = items.select { |i| i.kind_of?(Distribution) && i.state == 1}
      VersionEx.filter(distribution: { state: '1' })
        .map { |v| v.item } .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Distribution) &&
                                    i.storekeeper == st}
      VersionEx.filter(distribution: {
                        storekeeper: {
                          entity: { tag: 'storekeeper1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Distribution) &&
                                    i.storekeeper_place == stp}
      VersionEx.filter(distribution: {
                        storekeeper_place: {
                          place: { tag: 'sk_place1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Distribution) &&
                                    i.foreman == fr}
      VersionEx.filter(distribution: {
                        foreman: {
                          entity: { tag: 'foreman1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      filtered = items.select { |i| i.kind_of?(Distribution) &&
                                    i.foreman_place == frp}
      VersionEx.filter(distribution: {
                        foreman_place: {
                          place: { tag: 'fr_place1'}}}).map { |v| v.item }
        .eql?(filtered).should be_true

      VersionEx.filter.class.name.should eq('ActiveRecord::Relation')
    end
  end
end
