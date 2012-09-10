# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillItem
  attr_reader :amount, :price

  def resource
    return @resource if !@resource || !@resource.new_record?
    Asset.find_by_tag_and_mu(@resource.tag, @resource.mu) or @resource
  end

  def exp_amount
    return 0.0 unless self.resource
    resource_state = Warehouse.all(where: {
                         warehouse_id: { equal: @object.storekeeper_place.id },
                         'assets.id' => { equal_attr: self.resource.id } }).first
    return 0.0 unless resource_state
    resource_state.exp_amount
  end

  def initialize(attrs = {})
    @object = attrs[:object]
    @resource = attrs[:resource]
    @amount = attrs[:amount].kind_of?(String) ? attrs[:amount].to_f : attrs[:amount]
    @price = (attrs[:price] && attrs[:price].kind_of?(String)) ? attrs[:price].to_f :
        attrs[:price]
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
        tag: I18n.t("activerecord.attributes.#{
                      @object.class.name.downcase}.deal.resource.tag",
          id: @object.has_attribute?(:document_id) ? @object.document_id :
              (Allocation.last.nil? ? 1 : Allocation.last.id + 1),
          index: @object.items.rindex(self) + 1))
      return nil if deal.build_give(place: place, resource: give_r).nil?
      return nil if deal.build_take(place: place, resource: self.resource).nil?
      return nil unless deal.save
    end
    deal
  end

  def sum
    sum = self.amount * self.price
    sum.instance_of?(Float) ? sum.accounting_norm : sum
  end
end
