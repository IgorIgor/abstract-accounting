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

    record.items.each_with_index do |item, index|
      deal = record.create_storekeeper_deal(item, index)
      record.errors[:items] = 'invalid' if !deal || deal.new_record?
      warehouse_amount = item.exp_amount
      if (item.amount > warehouse_amount) || (item.amount <= 0)
        record.errors[:items] = I18n.t("errors.messages.less_than_or_equal_to",
                                       count: warehouse_amount)
      end
    end
  end
end

class Allocation < ActiveRecord::Base
  include Helpers::WarehouseDeal
  act_as_warehouse_deal from: :storekeeper, to: :foreman

  warehouse_attr :storekeeper, polymorphic: true,
                 reader: -> { self.deal.nil? ? nil : self.deal.entity }
  warehouse_attr :foreman, polymorphic: true,
                 reader: -> { self.deal.nil? ? nil : self.deal.rules.first.to.entity }
  warehouse_attr :storekeeper_place, class: Place,
                 reader: -> { self.deal.nil? ? nil : self.deal.give.place }
  warehouse_attr :foreman_place, class: Place,
                 reader: -> { self.deal.nil? ? nil : self.deal.take.place }

  sifter :date_range do |start, stop|
    (created >= start.beginning_of_day) & (created <= stop.end_of_day)
  end

  scope :without_deal_id, ->(deal_ids) { where{deal_id.not_in(deal_ids)} }

  class << self
    def by_warehouse(place)
      joins{deal.give}.
          where{deal.give.place_id == place.id}
    end
  end

  validates_with AllocationItemsValidator

  before_item_save :do_before_item_save

  MOTION_ALLOCATION = 0
  MOTION_INNER = 1

  custom_sort(:storekeeper) do |dir|
    query = "entities.tag"
    joins{deal.entity(Entity)}.order("#{query} #{dir}")
  end

  custom_sort(:storekeeper_place) do |dir|
    query = "places.tag"
    joins{deal.give.place}.order("#{query} #{dir}")
  end

  custom_sort(:foreman) do |dir|
    query = "entities.tag"
    joins{deal.rules.to.entity(Entity)}.
        group('allocations.id, allocations.created, allocations.deal_id, entities.tag').
        order("#{query} #{dir}")
  end

  custom_search(:foreman) do |value|
    joins{deal.rules.to.entity(Entity)}.uniq.
        where{lower(deal.rules.to.entity.tag).like(lower("%#{value}%"))}
  end

  custom_search(:storekeeper) do |value|
    joins{deal.entity(Entity)}.
        where{lower(deal.entity.tag).like(lower("%#{value}%"))}
  end

  custom_search(:storekeeper_place) do |value|
    joins{deal.give.place}.
        where{lower(deal.give.place.tag).like(lower("%#{value}%"))}
  end

  custom_search(:resource_tag) do |value|
    joins{deal.rules.from.give.resource(Asset)}.uniq.
        where{lower(deal.rules.from.give.resource.tag).like(lower("%#{value}%"))}
  end

  custom_search(:created) do |value|
    where{to_char(created, "YYYY-MM-DD").like(lower("%#{value}%"))}
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

  def motion
    self.deal.give.place_id == self.deal.take.place_id ? MOTION_ALLOCATION : MOTION_INNER
  end

  def create_foreman_deal(item, idx)
    deal = create_deal(item.resource, item.resource,
                      storekeeper_place, foreman_place,
                      foreman, 1.0, idx)
    deal.limit.update_attributes(amount: item.amount) if deal && self.motion == MOTION_INNER
    deal
  end

  private
    def do_before_item_save(item)
      return false if item.resource.new_record?
      true
    end
end
