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
    resource_state.real_amount
  end

  def initialize(attrs = {})
    @object = attrs[:object]
    @resource = attrs[:resource]
    @amount = attrs[:amount].kind_of?(String) ? attrs[:amount].to_f : attrs[:amount]
    @price = (attrs[:price] && attrs[:price].kind_of?(String)) ? attrs[:price].to_f :
        attrs[:price]
  end

  def sum
    sum = self.amount * self.price
    sum.instance_of?(Float) ? sum.accounting_norm : sum
  end
end
