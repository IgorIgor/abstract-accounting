# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ItemsValidator < ActiveModel::Validator
  def validate(record)
    record.errors[:items] <<
      'must exist' if record.items.empty?
    items = []
    record.items.each { |item|
      record.errors[:items] <<
        'invalid' if item.resource.nil? || item.resource.invalid?
      record.errors[:items] << 'invalid amount' if item.amount <= 0
      record.errors[:items] << 'invalid price' if item.price <= 0
      unless items.select{|i| (i[:tag] == item.resource.tag) &&
                              (i[:mu] == item.resource.mu) &&
                              (i[:price] == item.price)} .empty?
        record.errors[:items] << 'two identical resources'
      end
      items << {tag: item.resource.tag, mu: item.resource.mu, price: item.price}
    }
  end
end

class Waybill < ActiveRecord::Base
  has_paper_trail

  validates :document_id, :distributor, :distributor_place, :storekeeper,
            :storekeeper_place, :created, :presence => true
  validates_uniqueness_of :document_id
  validates_with ItemsValidator

  belongs_to :deal
  belongs_to :distributor, :polymorphic => true
  belongs_to :storekeeper, :polymorphic => true
  belongs_to :distributor_place, :class_name => 'Place'
  belongs_to :storekeeper_place, :class_name => 'Place'

  attr_reader :items

  after_initialize :do_after_initialize
  before_save :do_before_save

  def add_item(tag, mu, amount, price)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    resource = Asset.new(:tag => tag, :mu => mu) if resource.nil?
    @items << WaybillItem.new(resource, amount, price)
  end

  private
  def do_after_initialize
    @items = Array.new
  end

  def do_before_save
    if self.new_record?
      self.deal = Deal.new(entity: self.storekeeper, rate: 1.0, isOffBalance: true,
        tag: "Waybill shipment ##{Waybill.last.nil? ? 0 : Waybill.last.id}")
      shipment = Asset.find_or_create_by_tag('Warehouse Shipment')
      return false if self.deal.build_give(place: self.distributor_place,
                                           resource: shipment).nil?
      return false if self.deal.build_take(place: self.storekeeper_place,
                                           resource: shipment).nil?
      return false unless self.deal.save

      @items.each { |item, idx|
        return false unless item.resource.save if item.resource.new_record?

        distributor_item = item.warehouse_deal(Chart.first.currency,
                                               self.distributor_place, self.distributor)
        return false if distributor_item.nil?
        storekeeper_item = item.warehouse_deal(nil, self.storekeeper_place,
                                               self.storekeeper)
        return false if storekeeper_item.nil?

        return false if deal.rules.create(tag: "#{deal.tag}; rule#{idx}",
          from: distributor_item, to: storekeeper_item, fact_side: false,
          change_side: true, rate: item.amount).nil?
      }

      return false if Fact.create(amount: 1.0, resource: self.deal.give.resource,
        day: DateTime.current.change(hour: 12), to: self.deal).nil?
    else
      return false
    end
    true
  end
end

class WaybillItem
  attr_reader :resource, :amount, :price

  def initialize(resource, amount, price)
    @resource = resource
    @amount = amount
    @price = price
  end

  def warehouse_deal(give_r, place, entity)
    rate = give_r.nil? ? 1.0 : self.price
    give_r ||= self.resource

    deal = Deal.all(
      joins: ["INNER JOIN terms AS gives ON gives.deal_id = deals.id
                 AND gives.side = 'f'",
              "INNER JOIN terms AS takes ON takes.deal_id = deals.id
                 AND takes.side = 't'"],
      conditions: ["gives.resource_id = ? AND gives.place_id = ? AND
                    takes.resource_id = ? AND takes.place_id = ? AND
                    deals.entity_id = ? AND deals.entity_type = ? AND deals.rate = ?",
                  give_r, place, self.resource, place, entity, entity.class.name, rate]
    ).first
    if deal.nil?
      deal = Deal.new(entity: entity, rate: rate, isOffBalance: true,
        tag: "storehouse resource: #{self.resource.tag}[#{self.resource.mu}]; rate: #{rate}")
      return nil if deal.build_give(place: place, resource: give_r).nil?
      return nil if deal.build_take(place: place, resource: self.resource).nil?
      return nil unless deal.save
    end
    deal
  end
end

