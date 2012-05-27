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
  include Statable
  act_as_statable

  validates :document_id, :distributor, :distributor_place, :storekeeper,
            :storekeeper_place, :created, :presence => true
  validates_uniqueness_of :document_id
  validates_with ItemsValidator

  belongs_to :deal
  belongs_to :distributor, :polymorphic => true
  belongs_to :storekeeper, :polymorphic => true
  belongs_to :distributor_place, :class_name => 'Place'
  belongs_to :storekeeper_place, :class_name => 'Place'

  after_initialize :do_after_initialize
  before_save :do_before_save
  after_apply :do_after_apply

  def add_item(tag, mu, amount, price)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    resource = Asset.new(:tag => tag, :mu => mu) if resource.nil?
    @items << WaybillItem.new(self, resource, amount, price)
  end

  def items
    if @items.empty? and !self.deal.nil?
      self.deal.rules.each { |rule|
        @items << WaybillItem.new(self, rule.from.take.resource, rule.rate,
                                  (1.0 / rule.from.rate).accounting_norm)
      }
    end
    @items
  end

  def self.in_warehouse(attrs = {})
    condition = ''
    if attrs.has_key?(:where)
      attrs[:where].each do |attr, value|
        if value.kind_of?(Hash) && value.has_key?(:equal)
          condition << (condition.empty? ? ' AND' : 'WHERE')
          condition << " waybills.#{attr} = '#{value[:equal]}'"
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
                 states.amount as amount FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN states ON states.deal_id = rules.to_id
                              AND states.paid IS NULL
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
          #{condition}
          GROUP BY waybills.id, rules.to_id
          UNION
          SELECT waybills.id as id, assets.id as asset_id,
                 -SUM(ds_rule.rate) as amount FROM waybills
            LEFT JOIN rules ON rules.deal_id = waybills.deal_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
            INNER JOIN rules AS ds_rule ON ds_rule.from_id = rules.to_id
            INNER JOIN distributions ON distributions.deal_id = ds_rule.deal_id
                                     AND distributions.state = 1
          #{condition}
          GROUP BY waybills.id, rules.to_id )
        GROUP BY id, asset_id
      ) WHERE exp_amount > 0
      GROUP BY id"

    Waybill.find(
      ActiveRecord::Base.connection.execute(script).map { |wb| wb['id'] })
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
      self.deal_id = self.deal.id

      @items.each { |item, idx|
        return false unless item.resource.save if item.resource.new_record?

        distributor_item = item.warehouse_deal(Chart.first.currency,
                                               self.distributor_place, self.distributor)
        return false if distributor_item.nil?

        storekeeper_item = item.warehouse_deal(nil, self.storekeeper_place,
                                               self.storekeeper)
        return false if storekeeper_item.nil?

        return false if self.deal.rules.create(tag: "#{deal.tag}; rule#{idx}",
          from: distributor_item, to: storekeeper_item, fact_side: false,
          change_side: true, rate: item.amount).nil?
      }
    end
    true
  end

  def do_after_apply(fact)
    if fact
      return !Txn.create(fact: fact).nil?
    end
    true
  end
end

class WaybillItem
  attr_reader :resource, :amount, :price

  def exp_amount
    Warehouse.all(where: { storekeeper_id: { equal: @waybill.storekeeper_id },
                         storekeeper_place_id: { equal: @waybill.storekeeper_place_id },
                         'assets.id' => { equal_attr: self.resource.id } })
           .first.exp_amount
  end

  def initialize(waybill, resource, amount, price)
    @waybill = waybill
    @resource = resource
    @amount = amount
    @price = price
  end

  def warehouse_deal(give_r, place, entity)
    deal_rate = give_r.nil? ? 1.0 : 1.0 / self.price
    give_r ||= self.resource
    take_r = self.resource

    deal = Deal.joins(:give, :take).where do
      (give.resource_id == give_r) & (give.place_id == place) &
      (take.resource_id == take_r) & (give.place_id == place) &
      (entity_id == entity) & (entity_type == entity.class.name) & (self.rate == deal_rate)
    end.first
    if deal.nil? && !self.resource.nil?
      deal = Deal.new(entity: entity, rate: deal_rate,
        tag: "storehouse resource: #{self.resource.tag}[#{self.resource.mu}];" +
          " warehouse: #{place.tag}; rate: #{deal_rate}")
      return nil if deal.build_give(place: place, resource: give_r).nil?
      return nil if deal.build_take(place: place, resource: self.resource).nil?
      return nil unless deal.save
    end
    deal
  end
end

