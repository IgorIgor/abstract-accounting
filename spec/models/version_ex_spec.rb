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
    let(:entity) { Factory(:entity) }
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
      Factory(:entity)
      versions = VersionEx.by_type(types)
      versions.each { |version| version.item_type.should eq(types[0]) }
      Factory(:legal_entity)
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

      per_page.times { Factory(:entity) }

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
end
