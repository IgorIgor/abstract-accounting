# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

class TestAttributes
  include ActiveModel::Dirty

  def self.columns_hash
    @columns_hash ||= {}
  end

  def variable(name)
    self.instance_variable_get("@#{name}")
  end
end

class TestRecord
  attr_reader :id
  def initialize(id = -1)
    @id = id
  end

  def self.find(id)
    new(id)
  end
end

describe Helpers::ReferenceAttrBuilder do
  subject { Helpers::ReferenceAttrBuilder }

  it "should assign options attribute" do
    opts = {polymorphic: true}
    subject.new(TestAttributes, :some, opts).options.should eq(opts)
  end

  it { subject.valid_options.should =~ [:class, :reader, :polymorphic] }

  describe "#polymorphic?" do
    it "should return true if polymorphic option is set" do
      subject.new(TestAttributes, :some, {polymorphic: true}).should be_polymorphic
    end
    it "should return false if polymorphic option is set to false" do
      subject.new(TestAttributes, :some, {polymorphic: false}).should_not be_polymorphic
    end
    it "should return false if polymorphic option isn't set" do
      subject.new(TestAttributes, :some).should_not be_polymorphic
    end
  end

  describe "#klass" do
    it "should return klass if option is set" do
      subject.new(TestAttributes, :some, {class: TestRecord}).klass.should eq(TestRecord)
    end
  end

  describe "#reader" do
    it "should return reader lambda if it is set" do
      reader = -> { self.some_ref.some_ref }
      subject.new(TestAttributes, :some, {reader: reader}).reader.should eq(reader)
    end
  end

  describe "#build" do
    it "should validate options when build called" do
      expect { subject.new(TestAttributes, :some).build }.to_not raise_error
      expect do
        subject.new(TestAttributes, :some, class: TestRecord,
                    reader: -> { self.some.other } ).build
      end.to_not raise_error
      temp = subject.valid_options
      subject.valid_options = [:class, :polymorphic]
      expect do
        subject.new(TestAttributes, :some, class: TestRecord, reader: -> { 1 }).build
      end.to raise_error
      expect do
        subject.new(TestAttributes, :some, class: TestRecord, klass: Deal ).build
      end.to raise_error
      subject.valid_options = temp
    end

    describe "define accessors" do

      it "should define attr accessor" do
        model = TestAttributes
        subject.new(model, :some).build
        model.new.should respond_to :some
        model.new.should respond_to "some=".to_sym
      end

      it "should define attr_id accessor" do
        model = TestAttributes
        subject.new(model, :some).build
        model.new.should respond_to :some_id
        model.new.should respond_to "some_id=".to_sym
      end

      it "should define attr_type if polymorphic is set to true" do
        model = TestAttributes
        subject.new(model, :some_poly, polymorphic: true).build
        model.new.should respond_to :some_poly_type
        model.new.should respond_to "some_poly_type=".to_sym
      end

      it "shouldn't define attr_type if polymorphic is not set to true" do
        model = TestAttributes
        subject.new(model, :without_poly).build
        model.new.should_not respond_to :without_poly_type
        model.new.should_not respond_to "without_poly_type=".to_sym
      end

      it "should assign logic for attr accessors" do
        object = TestAttributes.new
        some = TestRecord.new
        object.some = some
        object.some.should eq(some)
      end

      it "should assign logic for attr_id accessors" do
        object = TestAttributes.new
        object.some_id = 1
        object.some_id.should eq(1)
      end

      it "should assign logic for attr_type accessors" do
        object = TestAttributes.new
        object.some_poly_type = TestRecord
        object.some_poly_type.should eq(TestRecord)
      end

      it "should clear other fields if one of is set" do
        object = TestAttributes.new
        object.some = TestRecord.new
        object.variable(:some).should_not be_nil
        object.some_id = 1
        object.variable(:some).should be_nil

        object = TestAttributes.new
        object.some_poly = TestRecord.new
        object.variable(:some_poly).should_not be_nil
        object.some_poly_id = 1
        object.some_poly_type = TestRecord
        object.variable(:some_poly).should be_nil

        object = TestAttributes.new
        object.some_poly_id = 1
        object.some_poly_type = TestRecord
        object.some_poly = TestRecord.new
        object.variable(:some_poly).should_not be_nil
        object.variable(:some_poly_id).should be_nil
        object.variable(:some_poly_type).should be_nil
      end

      it "should load data if sub data is set" do
        subject.new(TestAttributes, :record, class: TestRecord).build

        object = TestAttributes.new
        object.record = TestRecord.new(3)
        object.record_id.should eq(3)

        object.record = nil
        object.record_id.should be_nil

        object.record_id = 4
        object.record.should be_kind_of(TestRecord)
        object.record.id.should eq(4)

        subject.new(TestAttributes, :precord, polymorphic: true).build

        object = TestAttributes.new
        object.precord = TestRecord.new(5)
        object.precord_id.should eq(5)
        object.precord_type.should eq(TestRecord.name)

        object.precord = nil
        object.precord_id.should be_nil
        object.precord_type.should be_nil

        object.precord_id = 6
        object.record.should be_nil
        object.precord_type = TestRecord
        object.precord.should be_kind_of(TestRecord)
        object.precord.id.should eq(6)
      end

      it "should add columns to model" do
        subject.new(TestAttributes, :column, class: TestRecord).build

        TestAttributes.columns_hash.should be_has_key("column_id")

        subject.new(TestAttributes, :pcolumn, polymorphic: true).build

        TestAttributes.columns_hash.should be_has_key("pcolumn_id")

        TestAttributes.columns_hash.should be_has_key("pcolumn_type")
      end

      it "should use notify about changes in sub attributes if main attribute is changed" do
        subject.new(TestAttributes, :change_checked, class: TestRecord).build
        object = TestAttributes.new
        object.should_not be_change_checked_id_changed
        object.change_checked = TestRecord.new(8)
        object.should be_change_checked_id_changed

        subject.new(TestAttributes, :pchange_checked, polymorphic: true).build
        object = TestAttributes.new
        object.should_not be_pchange_checked_id_changed
        object.should_not be_pchange_checked_type_changed
        object.pchange_checked = TestRecord.new(8)
        object.should be_pchange_checked_id_changed
        object.should be_pchange_checked_type_changed
      end

      it "should use notify about changes in main attribute if sub attributes are changed" do
        object = TestAttributes.new
        object.should_not be_change_checked_id_changed
        object.change_checked_id = 9
        object.should be_change_checked_id_changed

        object = TestAttributes.new
        object.should_not be_pchange_checked_type_changed
        object.pchange_checked_type = TestRecord
        object.should_not be_pchange_checked_id_changed
        object.should be_pchange_checked_type_changed
      end
    end
  end

  describe "#model" do
    it "should accept model attribute" do
      model = TestAttributes
      subject.new(model, :some, class: TestRecord, reader: -> { 1 }).model.should eq(model)
    end
  end

  describe "#name" do
    it "should accept name attribute" do
      subject.new(TestAttributes, :some).name.should eq(:some)
    end
  end
end
