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
      record.errors[:items] << 'invalid amount' if item.amount <= 0
      record.errors[:items] << 'invalid price' if item.price <= 0
    end
  end
end

class Waybill < ActiveRecord::Base
  include WarehouseDeal
  act_as_warehouse_deal from: :distributor,
                        from_currency: lambda { Chart.first.currency },
                        to: :storekeeper,
                        item: :find_or_initialize

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
  end

  validates_presence_of :document_id
  validates_uniqueness_of :document_id
  validates_with ItemsValidator

  after_apply :do_apply_txn
  after_reverse :do_apply_txn
  before_item_save :do_before_item_save

  def self.order_by(attrs = {})
    field = nil
    scope = self
    case attrs[:field]
      when 'distributor'
        scope = scope.joins{deal.rules.from.entity(LegalEntity)}.
            group('waybills.id, waybills.created, waybills.document_id, waybills.deal_id, ' +
                  'legal_entities.name')
        field = 'legal_entities.name'
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
          mem.where{to_char(created, "YYYY-MM-DD").like(lower("%#{value}%"))}
        else
          mem.where{lower(__send__(key)).like(lower("%#{value}%"))}
      end
    end
  end

  def self.in_warehouse(attrs = {})
    condition = ''
    if attrs.has_key?(:where)
      attrs[:where].each do |attr, value|
        key = attr
        if attr.to_s == "warehouse_id"
          key = "places.id"
        end
        if value.kind_of?(Hash) && value.has_key?(:equal)
          condition << (condition.empty? ? ' AND' : 'WHERE')
          condition << " #{key} = '#{value[:equal]}'"
        end
      end
    end
    if attrs.has_key?(:without_waybills)
      condition << (condition.empty? ? 'WHERE' : ' AND')
      condition << " waybills.id NOT IN (#{attrs[:without_waybills].join(', ')})"
    end

    script = "
      SELECT T2.id FROM (
        SELECT T1.id, SUM(T1.amount) as exp_amount FROM (
          SELECT waybills.id as id, rules.to_id as to_id,
                 MAX(states.amount) as amount FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN states ON states.deal_id = rules.to_id
                              AND states.paid IS NULL
            INNER JOIN deals ON deals.id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN places ON places.id = terms.place_id
            INNER JOIN entities ON entities.id = deals.entity_id
          #{condition}
          GROUP BY waybills.id, rules.to_id
          UNION
          SELECT waybills.id as id, rules.to_id as to_id,
                 -SUM(ds_rule.rate) as amount FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN deals ON deals.id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN places ON places.id = terms.place_id
            INNER JOIN entities ON entities.id = deals.entity_id
            INNER JOIN rules AS ds_rule ON ds_rule.from_id = rules.to_id
            INNER JOIN deals as a_deals ON a_deals.id = ds_rule.deal_id
            INNER JOIN deal_states ON deal_states.deal_id = a_deals.id
                                   AND deal_states.closed IS NULL
          #{condition}
          GROUP BY waybills.id, rules.to_id ) T1
          INNER JOIN deals ON deals.id = T1.to_id
          INNER JOIN terms ON terms.deal_id = T1.to_id AND terms.side = 'f'
          INNER JOIN assets ON assets.id = terms.resource_id
        GROUP BY T1.id, assets.id
      ) T2 WHERE T2.exp_amount > 0
      GROUP BY T2.id"

    Waybill.find(
      ActiveRecord::Base.connection.execute(script).map { |wb| wb['id'] })
  end

  def sum
    sum = self.deal.rules.joins{from}.group{rules.deal_id}.
               select{sum(rules.rate / from.rate).as(:sum)}.first.sum
    Converter.float(sum)
  end

  private
  def initialize(attrs = nil)
    super(initialize_warehouse_attrs(attrs))
  end

  def do_apply_txn
    return !Txn.create(fact: self.fact).nil? if self.fact
    true
  end

  def do_before_item_save(item)
    return false unless item.resource.save if item.resource.new_record?
    true
  end
end
