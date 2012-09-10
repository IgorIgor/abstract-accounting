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
    def by_warehouse(place)
      joins{deal.give}.
          where{deal.give.place_id == place.id}
    end
  end

  validates_with AllocationItemsValidator

  before_item_save :do_before_item_save

  def self.order_by(attrs = {})
    field = nil
    scope = self
    case attrs[:field].to_s
      when 'storekeeper'
        scope = scope.joins{deal.entity(Entity)}
        field = 'entities.tag'
      when 'storekeeper_place'
        scope = scope.joins{deal.give.place}
        field = 'places.tag'
      when 'foreman'
        scope = scope.joins{deal.rules.to.entity(Entity)}.
            group('allocations.id, allocations.created, allocations.deal_id, entities.tag')
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

  def self.search(attrs = {})
    scope = attrs.keys.inject(scoped) do |mem, key|
      case key.to_s
        when 'foreman'
          mem.joins{deal.rules.to.entity(Entity)}.uniq
        when 'storekeeper'
          mem.joins{deal.entity(Entity)}
        when 'storekeeper_place'
          mem.joins{deal.give.place}
        when 'resource_tag'
          mem.joins{deal.rules.from.give.resource(Asset)}.uniq
        when 'state'
          mem.joins{deal.deal_state}.joins{deal.to_facts.outer}
        else
          mem
      end
    end
    attrs.inject(scope) do |mem, (key, value)|
      case key.to_s
        when 'foreman'
          mem.where{lower(deal.rules.to.entity.tag).like(lower("%#{value}%"))}
        when 'storekeeper'
          mem.where{lower(deal.entity.tag).like(lower("%#{value}%"))}
        when 'storekeeper_place'
          mem.where{lower(deal.give.place.tag).like(lower("%#{value}%"))}
        when 'resource_tag'
          mem.where{lower(deal.rules.from.give.resource.tag).like(lower("%#{value}%"))}
        when 'state'
          case value.to_i
            when Statable::INWORK
              mem.where{deal.deal_state.closed == nil}
            when Statable::APPLIED
              mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.amount == 1.0)}
            when Statable::CANCELED
              mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.id == nil)}
            when Statable::REVERSED
              mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.amount == -1.0)}
          end
        when 'created'
          mem.where{to_char(created, 'YYYY-MM-DD').like("%#{value}%")}
        else
          mem.where{lower(__send__(key)).like(lower("%#{value}%"))}
      end
    end
  end

  def document_id
    Allocation.last.nil? ? 1 : Allocation.last.id + 1
  end

  def foreman_place_or_new
    return Place.find(self.foreman_place.id) if self.foreman_place
    if self.warehouse_id
      Place.find(Allocation.extract_warehouse(self.warehouse_id)[:storekeeper_place_id])
    else
      Place.new
    end
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
