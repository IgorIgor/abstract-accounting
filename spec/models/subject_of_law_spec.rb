# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe SubjectOfLaw do
  before :all do
    3.times { create(:entity); create(:legal_entity) }
  end

  it "should have next classes" do
    SubjectOfLaw.klasses_i.should =~ [Entity, LegalEntity]
  end

  it "should return tag according to object" do
    obj = double("Entity")
    obj.stub(:id => Entity.first.id)
    obj.stub(:type => Entity.name)
    SubjectOfLaw.new(obj).tag.should eq(Entity.first.tag)
    obj = double("LegalEntity")
    obj.stub(:id => LegalEntity.first.id)
    obj.stub(:type => LegalEntity.name)
    SubjectOfLaw.new(obj).tag.should eq(LegalEntity.first.name)
  end
end
