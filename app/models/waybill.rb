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
          select{sum(deal.rules.rate/deal.rules.from.rate).as(:total)}.all
      total.inject(0.0){ |mem, item| mem + Converter.float(item.total) }
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

  custom_sort(:distributor) do |dir|
    query = "legal_entities.name"
    joins{deal.rules.from.entity(LegalEntity)}.order("#{query} #{dir}")
  end

  custom_sort(:storekeeper) do |dir|
    query = "entities.tag"
    joins{deal.entity(Entity)}.order("#{query} #{dir}")
  end

  custom_sort(:storekeeper_place) do |dir|
    query = "places.tag"
    joins{deal.take.place}.order("#{query} #{dir}")
  end

  custom_sort(:state) do |dir|
    query = "deal_states.state"
    joins{deal.deal_state}.order("#{query} #{dir}")
  end

  custom_sort(:sum) do |dir|
    query = "sum"
    joins{deal.rules.from}.
        group('waybills.id, waybills.created, waybills.document_id, waybills.deal_id').
        select{"waybills.*"}.
        select{sum(deal.rules.rate / deal.rules.from.rate).as(:sum)}.
        order("#{query} #{dir}")
  end

  custom_search(:distributor) do |value|
    joins{deal.rules.from.entity(LegalEntity)}.uniq.
        where{lower(deal.rules.from.entity.name).like(lower("%#{value}%"))}
  end

  custom_search(:storekeeper) do |value|
    joins{deal.entity(Entity)}.
        where{lower(deal.entity.tag).like(lower("%#{value}%"))}
  end

  custom_search(:storekeeper_place) do |value|
    joins{deal.take.place}.
        where{lower(deal.take.place.tag).like(lower("%#{value}%"))}
  end

  custom_search(:state) do |value|
    joins{deal.deal_state}.where{deal.deal_state.state == value}
  end

  custom_search(:resource_tag) do |value|
    joins{deal.rules.from.take.resource(Asset)}.uniq.
        where{lower(deal.rules.from.take.resource.tag).like(lower("%#{value}%"))}
  end

  custom_search(:created) do |value|
    where{to_char(created, "YYYY-MM-DD").like(lower("%#{value}%"))}
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
