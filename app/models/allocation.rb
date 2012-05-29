# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'waybill'

class AllocationItemsValidator < ActiveModel::Validator
  def validate(record)
    if record.state == Allocation::UNKNOWN
      record.errors[:items] << 'must exist' if record.items.empty?

      record.items.each do |item|
        deal = item.warehouse_deal(nil, record.storekeeper_place, record.storekeeper)
        record.errors[:items] = 'invalid' if deal.nil?
        if (item.amount > item.exp_amount) || (item.amount <= 0)
          record.errors[:items] = 'invalid amount'
        end
      end
    end
  end
end

class Allocation < ActiveRecord::Base
  has_paper_trail
  include Statable
  act_as_statable

  validates :foreman, :foreman_place, :storekeeper, :storekeeper_place,
            :created, :state, presence: true
  validates_with AllocationItemsValidator

  belongs_to :deal
  belongs_to :foreman, polymorphic: true
  belongs_to :storekeeper, polymorphic: true
  belongs_to :foreman_place, class_name: 'Place'
  belongs_to :storekeeper_place, class_name: 'Place'

  has_many :comments, :as => :item

  after_initialize :do_after_initialize
  before_save :do_before_save

  def add_item(tag, mu, amount)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    @items << AllocationItem.new(self, resource, amount)
  end

  def items
    if @items.empty? and !self.deal.nil?
      self.deal.rules.each do |rule|
        @items << AllocationItem.new(self, rule.from.take.resource, rule.rate)
      end
    end
    @items
  end

  private
  def do_after_initialize
    @items = Array.new
  end

  def do_before_save
    if self.new_record?
      shipment = Asset.find_or_create_by_tag('Warehouse Shipment')
      self.deal = Deal.new(entity: self.storekeeper, rate: 1.0, isOffBalance: true,
        tag: I18n.t('activerecord.attributes.allocation.deal.tag',
                    id: Allocation.last.nil? ? 1 : Allocation.last.id + 1))
      return false if self.deal.build_give(place: self.storekeeper_place,
                                           resource: shipment).nil?
      return false if self.deal.build_take(place: self.foreman_place,
                                           resource: shipment).nil?
      return false unless self.deal.save
      self.deal_id = self.deal.id

      @items.each do |item, idx|
        storekeeper_item = item.warehouse_deal(nil, self.storekeeper_place,
                                               self.storekeeper)
        return false if storekeeper_item.nil?

        foreman_item = item.warehouse_deal(nil, self.foreman_place, self.foreman)
        return false if foreman_item.nil?

        return false if self.deal.rules.create(tag: "#{deal.tag}; rule#{idx}",
          from: storekeeper_item, to: foreman_item, fact_side: false,
          change_side: true, rate: item.amount).nil?
      end
    end
    true
  end
end
