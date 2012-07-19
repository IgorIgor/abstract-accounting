# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Resource do
  before :all do
    3.times { create(:asset); create(:money) }
  end

  it "should be created by object with id and type" do
    Resource.class_eval do
      def object
        @object
      end
    end
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    Resource.new(obj).object.should eq(Asset.first)
  end

  it "should return id according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    Resource.new(obj).id.should eq(Asset.first.id)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    Resource.new(obj).id.should eq(Money.first.id)
  end

  it "should return tag according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    Resource.new(obj).tag.should eq(Asset.first.tag)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    Resource.new(obj).tag.should eq(Money.first.alpha_code)
  end

  it "should return ext info according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    Resource.new(obj).ext_info.should eq(Asset.first.mu)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    Resource.new(obj).ext_info.should eq(Money.first.num_code)
  end

  it "should return type according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    Resource.new(obj).type.should eq(Asset.name)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    Resource.new(obj).type.should eq(Money.name)
  end

  describe "#count" do
    it "should return total count of assets and money" do
      Resource.count.should eq(Asset.count + Money.count)
    end
  end

  describe "#all" do
    it "should return all assets and money as resource" do
      Resource.all.each do |item|
        item.should be_instance_of(Resource)
      end
    end

    it "should return paginated data" do
      Resource.all(page: 1, per_page: 4).count.should eq(4)
      Resource.all(page: 2, per_page: 4).count.should eq(Money.count + Asset.count - 4)
    end
  end
end
