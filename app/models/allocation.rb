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
  include WarehouseDeal
  act_as_warehouse_deal from: :storekeeper, to: :foreman, item: :find

  class << self
    def by_storekeeper(entity)
      joins{deal}.
          where{(deal.entity_id == entity.id) & (deal.entity_type == entity.class.name)}
    end
    def by_storekeeper_place(place)
      joins{deal.give}.
          where{deal.give.place_id == place.id}
    end
  end

  validates_with AllocationItemsValidator

  before_item_save :do_before_item_save

  def self.order_by(attrs = {})
    field = nil
    scope = self
    case attrs[:field]
      when 'storekeeper'
        scope = scope.joins{deal.entity(Entity)}
        field = 'entities.tag'
      when 'storekeeper_place'
        scope = scope.joins{deal.give.place}
        field = 'places.tag'
      when 'foreman'
        scope = scope.joins{deal.rules.to.entity(Entity)}.
            group('allocations.id')
        field = 'entities.tag'
      else
        field = attrs[:field] if attrs[:field]
    end
    unless field.nil?
      if attrs[:type] == 'desc'
        scope = scope.order("#{field} DESC")
      else
        scope = scope.order("#{field}")
      end
    end
    scope
  end

  def document_id
    Allocation.last.nil? ? 1 : Allocation.last.id + 1
  end

  private
  def initialize(attrs = nil)
    super(initialize_warehouse_attrs(attrs))
  end

  def do_before_item_save(item)
    return false if item.resource.new_record?
    true
  end
end
