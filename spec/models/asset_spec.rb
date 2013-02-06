# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Asset do
  it "should have next behaviour" do
    create(:asset)
    should validate_presence_of :tag
    should validate_uniqueness_of(:tag).scoped_to(:mu)
    should have_many(:terms)
    should have_many(:terms_as_give).class_name(Term).conditions(:side => false)
    should have_many(:terms_as_take).class_name(Term).conditions(:side => true)
    should have_many(:deal_gives).class_name(Deal).through(:terms_as_give)
    should have_many(:deal_takes).class_name(Deal).through(:terms_as_take)
    should have_many Asset.versions_association_name
    should belong_to(:detail).class_name(DetailedAsset)
  end

  it "should search by lower tag" do
    create(:asset, tag: "TAg")
    Asset.with_lower_tag_eq_to("taG").should eq(Asset.where{lower(tag) == lower("taG")})
  end

  it "should search by lower mu" do
    create(:asset, mu: "TAg")
    Asset.with_lower_mu_eq_to("taG").should eq(Asset.where{lower(mu) == lower("taG")})
  end
end
