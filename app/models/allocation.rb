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
    record.errors[:items] << I18n.t('errors.messages.blank') if record.items.empty?

    record.items.each do |item|
      deal = item.warehouse_deal(nil, record.storekeeper_place, record.storekeeper_place, record.storekeeper)
      record.errors[:items] = 'invalid' if deal.nil?
      warehouse_amount = item.exp_amount
      if (item.amount > warehouse_amount) || (item.amount <= 0)
        record.errors[:items] = I18n.t("errors.messages.less_than_or_equal_to",
                                       count: warehouse_amount)
      end
    end
  end
end

class AllocationMotionValidator < ActiveModel::Validator
  def validate(record)
    case record.motion
      when Allocation::ALLOCATION
        if record.foreman_place.nil?
          record.errors[:foreman_place] = I18n.t("errors.messages.blank")
        end
      when Allocation::INNER_MOTION
        if record.storekeeper_place == record.foreman_place
          record.errors[:foreman_place] = I18n.t("errors.messages.not_equal_to",
                                                 value: record.storekeeper_place)
        end
    end
  end
end

class Allocation < ActiveRecord::Base
  include WarehouseDeal
  act_as_warehouse_deal from: :storekeeper, to: :foreman

  class << self
    def by_warehouse(place)
      joins{deal.give}.
          where{deal.give.place_id == place.id}
    end
  end

  validates_presence_of :document_id, :storekeeper_place
  validates_with AllocationItemsValidator, AllocationMotionValidator

  before_item_save :do_before_item_save
  after_apply :create_waybill_after_apply

  ALLOCATION = 0
  INNER_MOTION = 1
  CHARGE_OFF = 2

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
            when INWORK
              mem.where{deal.deal_state.closed == nil}
            when APPLIED
              mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.amount == 1.0)}
            when CANCELED
              mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.id == nil)}
            when REVERSED
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
    if self.new_record?
      Allocation.last.nil? ? 1 : Allocation.last.id + 1
    else
      self.id.to_s
    end
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

  def create_waybill_after_apply
    return false unless self.motion == Allocation::INNER_MOTION
    waybill = nil
    begin
      Waybill.transaction do
        storekeeper = Credential.find_all_by_document_type_and_place_id(
            Waybill.name, self.foreman_place.id).first.user.entity
        waybill = Waybill.new(created: self.created, document_id: self.id, deal_id: self.deal.id)
        waybill.distributor = self.foreman
        waybill.storekeeper = storekeeper
        waybill.distributor_place = self.storekeeper_place
        waybill.storekeeper_place = self.foreman_place
        self.deal.rules.each do |rule|
          waybill.add_item({ tag: rule.to.give.resource.tag,
                             mu: rule.to.give.resource.mu,
                             amount: rule.rate,
                             price: rule.to.balance.value / rule.to.balance.amount })
        end
        waybill.save!
      end
    rescue
      raise
    end
  end
end
