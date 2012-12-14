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
    record.errors[:items] << I18n.t(
      "activerecord.errors.models.waybill.items.blank") if record.items.empty?
    record.items.each do |item|
      record.errors[:items] <<
        'invalid' if item.resource.nil? || item.resource.invalid?
      record.errors[:items] << I18n.t("activerecord.errors.messages.greater_than",
                                      count: 0) if item.amount <= 0
      record.errors[:items] << I18n.t("activerecord.errors.messages.greater_than",
                                      count: 0) if item.price <= 0
    end
  end
end

class Waybill < ActiveRecord::Base
  include WarehouseDeal
  act_as_warehouse_deal from: :distributor,
                        to: :storekeeper,
                        item: :initialize

  class << self
    def by_warehouse(warehouse)
      joins{deal.take}.
          where{deal.take.place_id == warehouse.id}
    end

    def total
      total = joins{deal.rules.from}.
          select{sum(deal.rules.rate/deal.rules.from.rate).as(:total)}.first.total
      Converter.float(total)
    end

    def in_warehouse
      waybills_reversed = scoped.joins{deal.to_facts}.where{deal.to_facts.amount == -1}.
          select{waybills.id}.uniq
      scoped.where{id.not_in(waybills_reversed)}.
          joins{deal.to_facts}.where{deal.to_facts.amount == 1.0}.
          joins{deal.rules.to.states}.
          where{deal.rules.to.states.paid == nil}.uniq
    end

    def without(ids)
      where{id.not_in(ids)}
    end
  end

  validates_presence_of :document_id
  validates_with ItemsValidator

  before_item_save :do_before_item_save

  def self.order_by(attrs = {})
    field = nil
    scope = self
    case attrs[:field]
      when 'distributor'
        scope = scope.joins{deal.rules.from.entity(LegalEntity).outer}.
            joins{deal.rules.from.entity(Entity).outer}
        field = "case froms_rules.entity_type
                      when 'Entity'      then entities.tag
                      when 'LegalEntity' then legal_entities.name
                 end"
      when 'storekeeper'
        scope = scope.joins{deal.entity(Entity)}
        field = 'entities.tag'
      when 'storekeeper_place'
        scope = scope.joins{deal.take.place}
        field = 'places.tag'
      when 'sum'
        scope = scope.joins{deal.rules.from}.
                group('waybills.id, waybills.created, waybills.document_id, waybills.deal_id').
                select("waybills.*").
                select{sum(deal.rules.rate / deal.rules.from.rate).as(:sum)}
        field = 'sum'
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
        when 'distributor'
          mem.joins{deal.rules.from.entity(LegalEntity)}.uniq
        when 'storekeeper'
          mem.joins{deal.entity(Entity)}
        when 'storekeeper_place'
          mem.joins{deal.take.place}
        when 'resource_tag'
          mem.joins{deal.rules.from.take.resource(Asset)}.uniq
        when 'state'
          mem.joins{deal.deal_state}.joins{deal.to_facts.outer}
        else
          mem
      end
    end
    attrs.inject(scope) do |mem, (key, value)|
      case key.to_s
        when 'distributor'
          mem.where{lower(deal.rules.from.entity.name).like(lower("%#{value}%"))}
        when 'storekeeper'
          mem.where{lower(deal.entity.tag).like(lower("%#{value}%"))}
        when 'storekeeper_place'
          mem.where{lower(deal.take.place.tag).like(lower("%#{value}%"))}
        when 'resource_tag'
          mem.where{lower(deal.rules.from.take.resource.tag).like(lower("%#{value}%"))}
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
          mem.where{to_char(created, "YYYY-MM-DD").like(lower("%#{value}%"))}
        else
          mem.where{lower(__send__(key)).like(lower("%#{value}%"))}
      end
    end
  end

  def sum
    sum = self.deal.rules.joins{from}.group{rules.deal_id}.
               select{sum(rules.rate / from.rate).as(:sum)}.first.sum
    Converter.float(sum)
  end

  def create_distributor_deal(item, idx)
    deal = create_deal(Chart.first.currency, item.resource,
                      distributor_place, storekeeper_place,
                      distributor, (1.0 / item.price), idx)

    deal.limit.update_attributes(side: Limit::ACTIVE, amount: 0) if deal
    deal
  end

  private
  def initialize(attrs = nil)
    super(initialize_warehouse_attrs(attrs))
  end

  def do_before_item_save(item)
    return false unless item.resource.save if item.resource.new_record?
    true
  end
end
