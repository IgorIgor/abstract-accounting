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
    def by_storekeeper(entity)
      joins{deal}.
          where{(deal.entity_id == entity.id) & (deal.entity_type == entity.class.name)}
    end
    def by_storekeeper_place(place)
      joins{deal.take}.
          where{deal.take.place_id == place.id}
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
            group('waybills.id')
        field = 'legal_entities.name'
      when 'storekeeper'
        scope = scope.joins{deal.entity(Entity)}
        field = 'entities.tag'
      when 'storekeeper_place'
        scope = scope.joins{deal.take.place}
        field = 'places.tag'
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

  def self.in_warehouse(attrs = {})
    condition = ''
    if attrs.has_key?(:where)
      attrs[:where].each do |attr, value|
        if value.kind_of?(Hash) && value.has_key?(:equal)
          condition << (condition.empty? ? ' AND' : 'WHERE')
          condition << " #{attr} = '#{value[:equal]}'"
        end
      end
    end
    if attrs.has_key?(:without_waybills)
      condition << (condition.empty? ? 'WHERE' : ' AND')
      condition << " waybills.id NOT IN (#{attrs[:without_waybills].join(', ')})"
    end

    script = "
      SELECT id FROM (
        SELECT id, SUM(amount) as exp_amount FROM (
          SELECT waybills.id as id, assets.id as asset_id,
                 states.amount as amount, entities.id as storekeeper_id,
                 places.id as storekeeper_place_id FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN states ON states.deal_id = rules.to_id
                              AND states.paid IS NULL
            INNER JOIN deals ON deals.id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
            INNER JOIN places ON places.id = terms.place_id
            INNER JOIN entities ON entities.id = deals.entity_id
          #{condition}
          GROUP BY waybills.id, rules.to_id
          UNION
          SELECT waybills.id as id, assets.id as asset_id,
                 -SUM(ds_rule.rate) as amount, entities.id as storekeeper_id,
                 places.id as storekeeper_place_id FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN deals ON deals.id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
            INNER JOIN places ON places.id = terms.place_id
            INNER JOIN entities ON entities.id = deals.entity_id
            INNER JOIN rules AS ds_rule ON ds_rule.from_id = rules.to_id
            INNER JOIN allocations ON allocations.deal_id = ds_rule.deal_id
                                     AND allocations.state = 1
          #{condition}
          GROUP BY waybills.id, rules.to_id )
        GROUP BY id, asset_id
      ) WHERE exp_amount > 0
      GROUP BY id"

    Waybill.find(
      ActiveRecord::Base.connection.execute(script).map { |wb| wb['id'] })
  end

  private
  def initialize(attrs = nil)
    super(initialize_warehouse_attrs(attrs))
  end

  def do_apply_txn(fact)
    if fact
      return !Txn.create(fact: fact).nil?
    end
    true
  end

  def do_before_item_save(item)
    return false unless item.resource.save if item.resource.new_record?
    true
  end
end
