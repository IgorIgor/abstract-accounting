# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Document do
  before :all do
    PaperTrail.enabled = true
  end

  after :all do
    PaperTrail.enabled = false
  end

  describe '#lasts' do
    let(:entity) { create(:entity) }
    it 'should return one version if object was created' do
      versions = Document.lasts.where(
        "item_type='Entity' AND versions.item_id=#{entity.id}")
      entity.versions.last.id.should eq(versions.first.id)
      versions.count.should eq(1)
    end

    it 'should return last version after object was updated' do
      entity.update_attributes!(tag: 'new_tag')
      entity.versions.count.should eq(2)
      entity.update_attributes!(tag: 'new_tag2')
      entity.versions.count.should eq(3)
      versions = Document.lasts.where(
        "item_type='Entity' AND versions.item_id=#{entity.id}")
      entity.versions.last.id.should eq(versions.first.id)
      versions.count.should eq(1)
    end
  end

  describe "#by_user" do
    it "should return all records for root user" do
      create(:user)
      Document.where{item_type.in(Document.documents)}.should =~ Document.
          by_user(RootUser.new).all
    end

    it "should return records by user credentials" do
      user = create(:user)
      5.times do
        create(:entity)
      end
      Document.by_user(user).all.should be_empty
      create(:credential, user: user, document_type: Entity.name)
      Document.by_user(user).all.should be_empty
      Document.where{item_type.in([Entity.name])}.each do |v|
        v.update_attributes(whodunnit: user.id)
      end
      Document.by_user(user).all.should =~ Document.where{item_type.in([Entity.name])}
      create(:chart)
      5.times do
        wb = build(:waybill, storekeeper: user.entity)
        wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 10.0)
        wb.save!
        wb.apply.should be_true

        ds = build(:allocation, storekeeper: wb.storekeeper,
                                storekeeper_place: wb.storekeeper_place)
        ds.add_item(tag: 'roof', mu: 'm2', amount: 1)
        ds.save!
      end
      Document.by_user(user).all.should =~ Document.where{item_type.in([Entity.name])}.
          where{whodunnit == user.id.to_s}
      credential = create(:credential, user: user, document_type: Waybill.name)
      Document.by_user(user).all.should =~ Document.where{item_type.in([Entity.name])}.
                where{whodunnit == user.id.to_s}
      5.times do
        wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
        wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 10.0)
        wb.save!
        wb.apply.should be_true
      end
      create(:credential, user: user,
          place: credential.place, document_type: Allocation.name)
      Document.by_user(user).all.should =~ Document.
          where{item_type.in([Entity.name, Waybill.name])}.
          joins{item(Waybill).outer.deal.outer.take.outer}.
          where{((item.deal.entity_id == user.entity_id) &
                (item.deal.take.place_id == credential.place_id)) |
          (whodunnit == user.id.to_s)}.all
      5.times do
        wb = build(:waybill, storekeeper: user.entity, storekeeper_place: credential.place)
        wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 10.0)
        wb.save!
        wb.apply.should be_true

        ds = build(:allocation, storekeeper: wb.storekeeper,
                                storekeeper_place: wb.storekeeper_place)
        ds.add_item(tag: 'roof', mu: 'm2', amount: 1)
        ds.save!
      end
      Document.by_user(user).all.should =~ Document.
          where{item_type.in([Entity.name, Waybill.name, Allocation.name])}.
          where{id.in(
            Version.joins{item(Waybill).deal.take}.
                    where{(item.deal.entity_id == user.entity_id) &
                          (item.deal.take.place_id == credential.place_id)}.
                    select{id}
          ) | id.in(
            Version.joins{item(Allocation).deal.give}.
                    where{(item.deal.entity_id == user.entity_id) &
                          (item.deal.give.place_id == credential.place_id)}.
                    select{id}
          ) | (whodunnit == user.id.to_s)}
    end
  end

  describe '#paginate' do
    it 'should split records by pages' do
      per_page = Settings.root.per_page

      per_page.times { create(:entity) }

      ver1 = Document.paginate()
      ver1.count.should eq(per_page)

      ver2 = Document.paginate({page: 1})
      ver1.should eq(ver2)

      ver2 = Document.paginate({page: '1'})
      ver1.should eq(ver2)

      ver2 = Document.paginate({per_page: per_page})
      ver1.should eq(ver2)

      ver2 = Document.paginate({per_page: per_page.to_s})
      ver1.should eq(ver2)

      ver2 = Document.paginate({page: 1, per_page: per_page})
      ver1.should eq(ver2)

      ver2 = Document.paginate({page: '1', per_page: per_page.to_s})
      ver1.should eq(ver2)

      ver2 = Document.paginate({page: 2, per_page: per_page})
      (ver2 & ver1).empty?.should eq(true)
    end
  end

  describe '#filter' do
    it 'should filtered records' do
      pending "disabled while fix filter with new allocation and waybill fields"
      create(:chart) unless Chart.count > 0
      Version.where{item_type.in([Waybill.name, Allocation.name])}.delete_all
      items = []
      (0..2).each do |i|
        st = i < 2 ? create(:entity, tag: "storekeeper#{i}") :
            Entity.find_by_tag("storekeeper1")
        stp = create(:place, tag: "sk_place#{i}")
        ds = create(:legal_entity, name: "ds_name#{i}",
               identifier_name: "ds_id_name1",
               identifier_value: "ds_id_value#{i < 2 ? 1 : 2}")
        dsp = create(:place, tag: "ds_place#{i}")

        wb = build(:waybill, document_id: "test_document_id#{i}",
               storekeeper: st, storekeeper_place: stp, distributor: ds,
               distributor_place: dsp)
        wb.add_item(tag: 'roof', mu: 'm2', amount: 2, price: 1.0)
        wb.save!
        wb.apply.should be_true
        items << wb

        fr = create(:entity, tag: "foreman#{i}")
        frp = create(:place, tag: "fr_place#{i}")
        dsn = build(:allocation, storekeeper: st,
                storekeeper_place: stp, foreman: fr, foreman_place: frp)
        dsn.add_item(tag: 'roof', mu: 'm2', amount: 1)
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

      Document.filter().should eq(Document.all)

      filtered = items.select { |i| i.kind_of?(Waybill) }
      Document.filter(waybill: { created: Date.today.to_s[0,2] }).lasts
        .map { |v| v.item }.should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.document_id == 'test_document_id1'}
      Document.filter(waybill: { document_id: 'test_document_id1' }).lasts
        .map { |v| v.item }.should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) && i.storekeeper == st}
      Document.filter(waybill: {
                        storekeeper: {
                          entity: { tag: 'storekeeper1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.storekeeper_place == stp}
      Document.filter(waybill: {
                        storekeeper_place: {
                          place: { tag: 'sk_place1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) && i.distributor == ds}
      Document.filter(waybill: {
                        distributor: {
                          legal_entity: {
                            identifier_name: 'ds_id_name1',
                            identifier_value: 'ds_id_value1',
                            name: 'ds_name1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) &&
                                    i.distributor_place == dsp}
      Document.filter(waybill: {
                        distributor_place: {
                          place: { tag: 'ds_place1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) &&
        i.storekeeper == st && i.storekeeper_place == stp}
      Document.filter(waybill: {
                        storekeeper: {
                          entity: { tag: st.tag}},
                        storekeeper_place: {
                          place: { tag: stp.tag}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Waybill) &&
        i.storekeeper == st && i.storekeeper_place == stp}
      Document.filter(waybill: {
                        storekeeper: {
                          entity: { tag: st.tag}},
                        storekeeper_place: {
                          place: { tag: stp.tag}},
                        created: Date.today.to_s[0,2]}).lasts.map { |v| v.item }.
        should =~ filtered

      Document.filter(waybill: { created: Date.today.to_s[0,2] },
                       allocation: { created: Date.today.to_s[0,2] }).lasts
        .count.should eq(items.count)

      filtered = items.select { |i| (i.kind_of?(Waybill) &&
        i.storekeeper == st) || (i.kind_of?(Allocation) && i.storekeeper == st) }
      Document.filter(waybill: {
                        storekeeper: {
                          entity: { tag: st.tag}},
                        created: Date.today.to_s[0,2]},
                       allocation: {
                        storekeeper: {
                          entity: { tag: st.tag}},
                        created: Date.today.to_s[0,2] }).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Allocation) && i.state == 1}
      Document.filter(allocation: { state: '1' }).lasts
        .map { |v| v.item }.should =~ filtered

      filtered = items.select { |i| i.kind_of?(Allocation) &&
                                    i.storekeeper == st}
      Document.filter(allocation: {
                        storekeeper: {
                          entity: { tag: 'storekeeper1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Allocation) &&
                                    i.storekeeper_place == stp}
      Document.filter(allocation: {
                        storekeeper_place: {
                          place: { tag: 'sk_place1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Allocation) &&
                                    i.foreman == fr}
      Document.filter(allocation: {
                        foreman: {
                          entity: { tag: 'foreman1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      filtered = items.select { |i| i.kind_of?(Allocation) &&
                                    i.foreman_place == frp}
      Document.filter(allocation: {
                        foreman_place: {
                          place: { tag: 'fr_place1'}}}).lasts.map { |v| v.item }.
        should =~ filtered

      Document.filter.class.name.should eq('ActiveRecord::Relation')
    end
  end

  describe "#attributes" do
    let(:doc) { Document.where{item_type.in(Document.documents)}.first }

    it "should has document_id" do
      doc.document_id.should eq(doc.item.id)
    end

    it "should has document_name" do
      doc.document_name.should eq(doc.item.class.name)
    end

    it "should has document_content" do
      klass_associations = doc.item.class.reflect_on_all_associations(:belongs_to)
      value = if doc.item.class.method_defined?(:storekeeper)
        doc.item.storekeeper.tag
      elsif klass_associations.any? { |assoc| assoc.name == :entity }
        doc.item.entity.tag
      else
        doc.item.tag
      end
      doc.document_content.should eq(value)
    end

    it "should has document_created_at" do
      doc.document_created_at.should eq(doc.item.versions.first.created_at)
    end

    it "should has document_updated_at" do
      doc.document_updated_at.should eq(doc.item.versions.last.created_at)
    end
  end
end
