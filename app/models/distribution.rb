# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'waybill'

class DistributionItemsValidator < ActiveModel::Validator
  def validate(record)
    if record.state == Distribution::UNKNOWN
      record.errors[:items] << 'must exist' if record.items.empty?

      record.items.each { |item|
        deal = item.warehouse_deal(nil, record.storekeeper_place, record.storekeeper)
        record.errors[:items] = 'invalid' if deal.nil?
        if (item.amount > item.warehouse_state(record.storekeeper,
                                               record.storekeeper_place,
                                               record.created)) || (item.amount <= 0)
          record.errors[:items] = 'invalid amount'
        end
      }
    end
  end
end

class Distribution < ActiveRecord::Base
  has_paper_trail

  UNKNOWN = 0
  INWORK = 1
  CANCELED = 2
  APPLIED = 3

  validates :foreman, :foreman_place, :storekeeper, :storekeeper_place,
            :created, :state, presence: true
  validates_with DistributionItemsValidator

  belongs_to :deal
  belongs_to :foreman, polymorphic: true
  belongs_to :storekeeper, polymorphic: true
  belongs_to :foreman_place, class_name: 'Place'
  belongs_to :storekeeper_place, class_name: 'Place'

  after_initialize :do_after_initialize
  before_save :do_before_save

  def add_item(tag, mu, amount)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    @items << DistributionItem.new(resource, amount)
  end

  def items
    if @items.empty? and !self.deal.nil?
      self.deal.rules.each { |rule|
        @items << DistributionItem.new(rule.from.take.resource, rule.rate)
      }
    end
    @items
  end

  def cancel
    if self.state == INWORK
      self.state = CANCELED
      return self.save
    end
    false
  end

  def apply
    if self.state == INWORK and !self.deal.nil?
      return false if Fact.create(amount: 1.0, resource: self.deal.give.resource,
        day: DateTime.current.change(hour: 12), to: self.deal).nil?
      self.state = APPLIED
      return self.save
    end
    false
  end

  private
  def do_after_initialize
    @items = Array.new
    self.state = UNKNOWN if self.new_record?
  end

  def do_before_save
    if self.new_record?
      shipment = Asset.find_or_create_by_tag('Warehouse Shipment')
      self.deal = Deal.new(entity: self.storekeeper, rate: 1.0, isOffBalance: true,
        tag: "Distribution shipment ##{Distribution.last.nil? ? 0 : Distribution.last.id}")
      return false if self.deal.build_give(place: self.storekeeper_place,
                                           resource: shipment).nil?
      return false if self.deal.build_take(place: self.foreman_place,
                                           resource: shipment).nil?
      return false unless self.deal.save
      self.deal_id = self.deal.id

      @items.each { |item, idx|
        storekeeper_item = item.warehouse_deal(nil, self.storekeeper_place,
                                               self.storekeeper)
        return false if storekeeper_item.nil?

        foreman_item = item.warehouse_deal(nil, self.foreman_place, self.foreman)
        return false if foreman_item.nil?

        return false if self.deal.rules.create(tag: "#{deal.tag}; rule#{idx}",
          from: storekeeper_item, to: foreman_item, fact_side: false,
          change_side: true, rate: item.amount).nil?
      }
      self.state = INWORK if self.state == UNKNOWN
    end
    true
  end
end

class DistributionItem < WaybillItem
  def initialize(resource, amount)
    @resource = resource
    @amount = amount
  end

  def warehouse_state entity, place, date
      deal = self.warehouse_deal(nil, place, entity)
      return 0 if deal.nil?
      date += 1

      rules = Rule.where('rules.to_id = ?', deal).
              joins('INNER JOIN waybills ON waybills.deal_id = rules.deal_id').
              where('waybills.created <= ?', date)
      unless place.nil?
        rules.where('waybills.place_id = ?', place)
      end
      state = rules.sum('rules.rate')

      rules = Rule.where('rules.from_id = ?', deal).
              joins('INNER JOIN distributions ON distributions.deal_id = rules.deal_id').
              where('distributions.created <= ? AND distributions.state != ?',
                    date, Distribution::CANCELED)
      unless place.nil?
        rules.where('distributions.place_id = ?', place)
      end
      state - rules.sum('rules.rate')
  end
end
