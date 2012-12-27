# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

class DammyClass
  attr_reader :ordered
  attr_reader :limit_value, :offset_value

  include AppUtils::ARFilters

  def order(str)
    @ordered = str
    self
  end

  def limit(value)
    @limit_value = value
    self
  end

  def offset(value)
    @offset_value = value
    self
  end

  class << self
    def define_singleton_method(method, &block)
      define_method method, &block
      super
    end

    def attribute_names
      %w(id tag)
    end

    def scoped; DammyClass.new end
  end
end

class FiltrateClass

  include AppUtils::ARFilters

  class << self
    attr_reader :ordered
    attr_reader :limited, :offset_value

    def order(str)
      @ordered = str
      self
    end

    def limit(value)
      @limited = value
      self
    end

    def offset(value)
      @offset_value = value
      self
    end

    def attribute_names
      %w(id tag)
    end

    def scoped; self end
  end
end

class Searchable < ActiveRecord::Base
  has_no_table

  column :uid, :integer
  column :tag, :string

  custom_search :uid_s do |value|
    where{uid == my{value}}
  end

  class << self
    def attribute_names
      %w(uid tag)
    end
  end
end

describe AppUtils::ARFilters do
  it "should be included in active record" do
    ActiveRecord::Base.included_modules.include?(AppUtils::ARFilters)
  end

  describe "#custom_sort" do
    it "should create custom sort method" do
      DammyClass.class_eval do
        custom_sort(:name) { |dir| "Ordered by #{dir}" }
      end

      DammyClass.singleton_methods.should be_include(:sort_by_name)
      DammyClass.sort_by_name("ASC").should eq("Ordered by ASC")
    end
  end

  describe "#sort" do
    it "should call order" do
      DammyClass.sort("id", "desc").ordered.should eq("id desc")
    end

    it "should call order only for model attributes" do
      DammyClass.attribute_names.each do |name|
        DammyClass.sort(name, "desc").ordered.should eq("#{name} desc")
      end
      DammyClass.sort("haha", "desc").ordered.should be_nil
    end

    it "should call custom sort method if exists" do
      DammyClass.class_eval do
        custom_sort(:manager) { |dir| @ordered = "managers.tag #{dir}"; self }
      end
      DammyClass.sort("manager", "desc").ordered.should eq("managers.tag desc")
    end

    it "should accept params as hash" do
      DammyClass.class_eval do
        custom_sort(:manager) { |dir| @ordered = "managers.tag #{dir}"; self }
      end
      DammyClass.sort(field: "manager", type: "desc").ordered.should eq("managers.tag desc")
      DammyClass.attribute_names.each do |name|
        DammyClass.sort(field: name, type: "desc").ordered.should eq("#{name} desc")
      end
    end
  end

  describe "#paginate" do
    it "should call paginate" do
      obj = DammyClass.paginate(1, 10)
      obj.limit_value.should eq(10)
      obj.offset_value.should eq(0)
      obj = DammyClass.paginate(2, 10)
      obj.limit_value.should eq(10)
      obj.offset_value.should eq(10)
    end
    it "should accept hash as parameters" do
      obj = DammyClass.paginate(page: 1, per_page: 10)
      obj.limit_value.should eq(10)
      obj.offset_value.should eq(0)
      obj = DammyClass.paginate(page: 2, per_page: 10)
      obj.limit_value.should eq(10)
      obj.offset_value.should eq(10)
    end
  end

  describe "#search", focus: true do
    it "should filter by like attribute" do
      test = Searchable.search(tag: "hello")
      test.where_values.count.should eq(1)
      test.where_values[0].should be_kind_of(Squeel::Nodes::Predicate)
      test.where_values[0].expr.should be_kind_of(Squeel::Nodes::Function)
      test.where_values[0].expr.name.should eq(:lower)
      test.where_values[0].expr.args[0].should eq(Squeel::DSL.eval{tag})
      test.where_values[0].method_name.should eq(:matches)
      test.where_values[0].value.should be_kind_of(Squeel::Nodes::Function)
      test.where_values[0].value.name.should eq(:lower)
      test.where_values[0].value.args[0].should eq(Squeel::DSL.eval{"%hello%"})
    end

    it "should cast if attribute is not string" do
      test = Searchable.search(uid: "1")
      test.where_values.count.should eq(1)
      test.where_values[0].should be_kind_of(Squeel::Nodes::Predicate)
      test.where_values[0].expr.should be_kind_of(Squeel::Nodes::Function)
      test.where_values[0].expr.name.should eq(:cast)
      test.where_values[0].expr.args[0].should eql(Squeel::DSL.eval{uid.as("character(100)")})
      test.where_values[0].method_name.should eq(:matches)
      test.where_values[0].value.should eq(Squeel::DSL.eval{"%1%"})
    end

    it "should use scope before search" do
      test = Searchable.search(uid: "1", tag: "haha")
      test.where_values.count.should eq(2)
    end

    it "should call custom search method if exists" do
      test = Searchable.search(uid_s: 1)
      test.where_values.count.should eq(1)
      test.where_values[0].should eql(Squeel::DSL.eval{uid == my{1}})
    end
  end

  describe "#filtrate" do
    it "should call order and paginate from params" do
      FiltrateClass.filtrate(sort: { field: "tag", type: "desc" },
                             paginate: { page: 1, per_page: 10 }).
          name.should eq(FiltrateClass.name)
      FiltrateClass.ordered.should eq("tag desc")
      FiltrateClass.limited.should eq(10)
      FiltrateClass.offset_value.should eq(0)
      FiltrateClass.filtrate(sort: { field: "id", type: "asc" },
                             paginate: { page: 5, per_page: 10 })
      FiltrateClass.ordered.should eq("id asc")
      FiltrateClass.limited.should eq(10)
      FiltrateClass.offset_value.should eq(40)
    end
  end
end
