# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

class CombinedTest < Combined
  klasses [Asset, Money]
  combined_attribute :tag, Asset: :tag, Money: :alpha_code

  def object
    @object
  end
end

describe Combined do
  before :all do
    3.times { create(:asset); create(:money) }
  end

  it "should be created by object with id and type" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    CombinedTest.new(obj).object.should eq(Asset.first)
  end

  it "should return id according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    CombinedTest.new(obj).id.should eq(Asset.first.id)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    CombinedTest.new(obj).id.should eq(Money.first.id)
  end

  it "should return type according to object" do
    obj = double("asset")
    obj.stub(:id => Asset.first.id)
    obj.stub(:type => Asset.name)
    CombinedTest.new(obj).type.should eq(Asset.name)
    obj = double("money")
    obj.stub(:id => Money.first.id)
    obj.stub(:type => Money.name)
    CombinedTest.new(obj).type.should eq(Money.name)
  end

  describe "#combined_attribute" do
    it "should create attribute" do
      obj = double("asset")
      obj.stub(:id => Asset.first.id)
      obj.stub(:type => Asset.name)
      CombinedTest.new(obj).should respond_to(:tag)
    end

    it "should return attribute value by configuration" do
      obj = double("asset")
      obj.stub(:id => Asset.first.id)
      obj.stub(:type => Asset.name)
      CombinedTest.new(obj).tag.should eq(Asset.first.tag)
      obj = double("money")
      obj.stub(:id => Money.first.id)
      obj.stub(:type => Money.name)
      CombinedTest.new(obj).tag.should eq(Money.first.alpha_code)
    end
  end

  describe "#count" do
    it "should return total count of assets and money" do
      CombinedTest.count.should eq(Asset.count + Money.count)
    end
  end

  describe "#all" do
    it "should return all assets and money as resource" do
      CombinedTest.all.each do |item|
        item.should be_instance_of(CombinedTest)
      end
    end

    it "should return paginated data" do
      CombinedTest.all(page: 1, per_page: 4).count.should eq(4)
      CombinedTest.all(page: 2, per_page: 4).count.should eq(Money.count + Asset.count - 4)
    end
  end

  describe "#where" do
    it "should select resources with where condition" do
      arr = CombinedTest.where({tag: {like: 'e'}}).all.collect{ |item| item.id }
      arr_test = (Money.where("alpha_code LIKE '%e%'") + Asset.where("tag LIKE '%e%'")).
          collect { |item| item.id }
      arr.should =~ arr_test
    end
  end

  describe "#limit" do
    it "should select resources with limit" do
      arr = CombinedTest.limit(2).all.count.should eq(2)
    end
  end

  describe "#order_by" do
    it "should select resources with order" do
      arr = CombinedTest.order_by('tag').all.collect{ |item| item.id }
      arr_test = (Money.order('alpha_code') + Asset.order('tag')).
          sort! do |x, y|
            (x.instance_of?(Money) ? x.alpha_code : x.tag) <=>
                (y.instance_of?(Money) ? y.alpha_code : y.tag)
          end.map(&:id)
      arr.should eq(arr_test)
    end
  end
end
