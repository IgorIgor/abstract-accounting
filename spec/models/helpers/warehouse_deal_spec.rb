# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

class TestWarehouseDeal
  include ActiveModel::Dirty

  class << self
    attr_accessor :before_save_callback
    attr_accessor :after_save_callbacks

    def has_paper_trail
      @has_paper_trail = true
    end

    def paper_trail_included?
      @has_paper_trail
    end

    def before_save(callback)
      self.before_save_callback = callback
    end

    def after_save(callback)
      self.after_save_callbacks ||= []
      self.after_save_callbacks << callback
    end

    def has_many(*args)
    end

    def belongs_to(*args)
    end

    def validates_presence_of(*args)
    end

    def includes(*args)
    end

    def scope(*args)
    end

    def columns_hash
      @columns_hash ||= {}
    end
  end
  include Helpers::WarehouseDeal
  act_as_warehouse_deal from: :receiver, to: :storekeeper,
                        item: :initialize

  warehouse_attr :storekeeper, polymorphic: true
  warehouse_attr :storekeeper_place, class: Place

  warehouse_attr :receiver, polymorphic: true
  warehouse_attr :receiver_place, class: Place

  before_item_save :do_before_item_save

  def save
    if self.send(self.class.before_save_callback)
      @previously_changed = changes
      @changed_attributes.clear
      self.class.after_save_callbacks.each { |callback| self.send(callback) }
      self.new_record = false
      self.deal_id_changed = false
      return true
    end
    false
  end

  attr_accessor :new_record
  def new_record?
    self.new_record
  end

  attr_accessor :id_changed
  def id_changed?
    self.id_changed
  end

  def invalid?
    false
  end

  def create_receiver_deal(item, index)
    create_deal(Chart.first.currency, item.resource, receiver_place, receiver_place,
                receiver, 1.0 / item.price, index)
  end

  attr_accessor :document_id
  attr_accessor :deal
  attr_accessor :items

  attr_accessor :do_before_item_save_called

  def update_attributes(args = {})
    args.each do |key, value|
      self.send("#{key}=", value)
    end
    self.save
  end

  attr_reader :deal_id
  attr_accessor :deal_id_changed
  def deal_id=(value)
    self.deal_id_changed = true
    @deal_id = value
  end
  def deal_id_changed?
    self.deal_id_changed
  end

  private
    def do_before_item_save(item)
      return false unless item.resource.save if item.resource.new_record?
      self.do_before_item_save_called = true
      true
    end

    def attributes
      {id: nil, deal_id: nil}
    end
end

class TestRecord

end

describe Helpers::WarehouseDeal do
  before(:all) { create(:chart) }

  subject { TestWarehouseDeal }
  it { should be_paper_trail_included }
  it { should include(Helpers::Statable) }
  it { should include(Helpers::Commentable) }

  describe "#warehouse_attr" do
    it "should generate attr accessors" do
      object = TestWarehouseDeal.new
      object.should respond_to :storekeeper_place
      object.should respond_to "storekeeper_place_id"
      object.should respond_to "storekeeper_place="
      object.should respond_to "storekeeper_place_id="

      object.should respond_to :storekeeper
      object.should respond_to "storekeeper_id"
      object.should respond_to "storekeeper_type"
      object.should respond_to "storekeeper="
      object.should respond_to "storekeeper_id="
      object.should respond_to "storekeeper_type="
    end
  end

  describe "#save" do
    it "should register before_save callback" do
      TestWarehouseDeal.before_save_callback.should_not be_nil
    end

    it "should create main deal" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.items = []

      deal_tag = I18n.t("activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag",
                        id: object.document_id, place: object.storekeeper_place.tag,
                        deal_id: Deal.count > 0 ? Deal.last.id + 1 : 1)

      expect { object.save.should be_true }.
          to change(Deal, :count).by(1) && change(Asset, :count).by(1)
      object.deal.should_not be_nil
      object.deal_id.should_not be_nil
      object.deal_id.should eq(object.deal.id)

      object.deal.should_not be_new_record
      object.deal.entity.should eq(object.storekeeper)
      object.deal.isOffBalance.should be_true
      object.deal.rate.should eq(1.0)
      object.deal.tag.should eq(deal_tag)

      shipment = Asset.find_by_tag(I18n.t('activerecord.defaults.assets.shipment'))
      shipment.should_not be_nil

      object.deal.take.should_not be_nil
      object.deal.take.place.should eq(object.storekeeper_place)
      object.deal.take.resource.should eq(shipment)

      object.deal.give.should_not be_nil
      object.deal.give.place.should eq(object.receiver_place)
      object.deal.give.resource.should eq(shipment)
    end

    it "should not create deal if it's not a new record" do
      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.add_item tag: "SomeTag1111", mu: "SomeMU", amount: 10, price: 20
      expect { object.save.should be_true }.
          to change(Deal, :count).by(3)

      old_deal = object.deal.clone

      object.new_record = false
      expect { object.save.should be_true }.
          to change(Deal, :count).by(0)
      object.deal.should eq(old_deal)
    end

    it "should call callback for save resource" do
      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.add_item tag: "SomeTag1111", mu: "SomeMU", amount: 10, price: 20

      object.save.should be_true
      object.do_before_item_save_called.should be_true

      Asset.create(tag: "SomeTag22222", mu: "SomeMU")
      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.add_item tag: "SomeTag22222", mu: "SomeMU", amount: 10, price: 20

      callback = TestWarehouseDeal.before_item_save_callback
      TestWarehouseDeal.before_item_save_callback = nil

      object.save.should be_true
      object.do_before_item_save_called.should be_nil

      TestWarehouseDeal.before_item_save_callback = callback
    end

    it "should create rules from items" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.add_item tag: "SomeTag", mu: "SomeMU", amount: 10, price: 20

      expect { object.save.should be_true }.
          to change(Rule, :count).by(1)

      object.deal.rules.count.should eq(1)
      rule = object.deal.rules.first
      rule.rate.should eq(10)
      rule.change_side.should be_true
      rule.fact_side.should be_false
      rule.tag.should eq("#{object.deal.tag}; rule#{0}")
      rule.from_id.should_not be_nil
      rule.to_id.should_not be_nil

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag1", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag2", mu: "SomeMU2", amount: 10, price: 20

      expect { object.save.should be_true }.
          to change(Rule, :count).by(2)

      object.deal.rules.count.should eq(2)
    end

    it "should create deals for all items" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid"
      object.add_item tag: "SomeTag31", mu: "SomeMU", amount: 10, price: 20

      expect { object.save.should be_true }.to change(Deal, :count).by(3)
      object.items.each_with_index do |item, idx|
        deal = object.create_storekeeper_deal(item, idx)
        object.deal.rules.where{to_id == my{deal.id}}.count.should eq(1)
        deal = object.create_receiver_deal(item, idx)
        object.deal.rules.where{from_id == my{deal.id}}.count.should eq(1)
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag32", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag33", mu: "SomeMU2", amount: 10, price: 20

      expect { object.save.should be_true }.to change(Deal, :count).by(5)
      object.items.each_with_index do |item, idx|
        deal = object.create_storekeeper_deal(item, idx)
        object.deal.rules.where{to_id == my{deal.id}}.count.should eq(1)
        deal = object.create_receiver_deal(item, idx)
        object.deal.rules.where{from_id == my{deal.id}}.count.should eq(1)
      end
    end

    it "should return false if rules is not created" do
      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag32", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag33", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_false
    end
  end

  describe "#update_attributes" do
    it "should return false if state is not INWORK" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag32", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag33", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_true
      object.apply.should be_true
      object.update_attributes(storekeeper_id: create(:entity).id).should be_false
    end

    it "should destroy old main deal and create new if storekeeper changed" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      object = TestWarehouseDeal.new
      object.storekeeper = create(:entity)
      object.storekeeper_place = create(:place)
      object.receiver = create(:entity)
      object.receiver_place = create(:place)
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag32", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag33", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_true

      old_deal = object.deal

      object.update_attributes(storekeeper_id: create(:entity).id).should be_true
      object.deal_id.should_not eq(old_deal.id)
      object.deal.should_not be_new_record
      object.deal.entity_id.should eq(object.storekeeper_id)

      old_deal = object.deal

      object.update_attributes(storekeeper: create(:legal_entity)).should be_true
      object.deal_id.should_not eq(old_deal.id)
      object.deal.should_not be_new_record
      object.deal.entity_type.should eq(object.storekeeper_type)
    end

    it "should destroy old main deal and create new if storekeeper_place changed" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      storekeeper, receiver = create(:entity), create(:entity)
      storekeeper_place, receiver_place = create(:place), create(:place)

      object = TestWarehouseDeal.new
      object.storekeeper = storekeeper
      object.storekeeper_place = storekeeper_place
      object.receiver = receiver
      object.receiver_place = receiver_place
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag321", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag331", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_true

      old_deal = object.deal.clone

      object.new_record = false
      object.id_changed = false

      storekeeper_place = create(:place)
      object.update_attributes(storekeeper_place_id: storekeeper_place.id).should be_true
      object.deal_id.should_not eq(old_deal.id)
      object.deal.should_not be_new_record
      object.deal.take.place_id.should eq(storekeeper_place.id)
    end

    it "should destroy old main deal and create new if receiver_place changed" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      storekeeper, receiver = create(:entity), create(:entity)
      storekeeper_place, receiver_place = create(:place), create(:place)

      object = TestWarehouseDeal.new
      object.storekeeper = storekeeper
      object.storekeeper_place = storekeeper_place
      object.receiver = receiver
      object.receiver_place = receiver_place
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag321", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag331", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_true

      old_deal = object.deal.clone

      object.new_record = false
      object.id_changed = false

      receiver_place = create(:place)
      object.update_attributes(receiver_place_id: receiver_place.id).should be_true
      object.deal_id.should_not eq(old_deal.id)
      object.deal.should_not be_new_record
      object.deal.give.place_id.should eq(receiver_place.id)
    end

    it "shouldn't destroy old main deal if receiver changed" do
      I18n.stub(:t) do |*args|
        case args[0]
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:place]} #{args[1][:deal_id]}"
          when "activerecord.attributes.#{TestWarehouseDeal.name.downcase}.deal.resource.tag"
            "#{args[0]} #{args[1][:id]} #{args[1][:index]} #{args[1][:deal_id]}"
          else
            args[0]
        end
      end

      storekeeper, receiver = create(:entity), create(:entity)
      storekeeper_place, receiver_place = create(:place), create(:place)

      object = TestWarehouseDeal.new
      object.storekeeper = storekeeper
      object.storekeeper_place = storekeeper_place
      object.receiver = receiver
      object.receiver_place = receiver_place
      object.new_record = true
      object.id_changed = true
      object.document_id = "someid2"
      object.add_item tag: "SomeTag321", mu: "SomeMU1", amount: 10, price: 20
      object.add_item tag: "SomeTag331", mu: "SomeMU2", amount: 10, price: 20
      object.save.should be_true

      old_deal = object.deal.clone

      object.new_record = false
      object.id_changed = false

      receiver = create(:entity)
      object.update_attributes(receiver_id: receiver.id).should be_true
      object.deal_id.should eq(old_deal.id)
      object.deal.should_not be_new_record
      object.deal.rules.count.should eq(object.items.count)
      object.deal.rules.each do |rule|
        rule.from.entity.should eq(receiver)
      end
    end
  end
end
