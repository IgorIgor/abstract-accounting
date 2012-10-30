# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
node(:id) { @allocation.id }
node(:type) { @allocation.class.name }
child(@allocation => :allocation) do
  attributes :id, :state, :warehouse_id, :motion
  node(:created) { |allocation| allocation.created.strftime('%Y-%m-%d') }
  glue @allocation.foreman do
    attributes :id => :foreman_id
  end
  glue @allocation.foreman_place do
    attributes :id => :foreman_place_id
  end
end
node(:owner) { @allocation.owner? }
node(:state) do
  partial "state/can_do", :object => @allocation
end
child(@allocation.foreman => :foreman) { attributes :tag }
child(@allocation.foreman_place => :foreman_place) { attributes :tag }
child(@allocation.items => :items) do
  attributes :amount
  node(:real_amount) { |item| item.exp_amount }
  glue :resource do
    attributes :id, :mu, :tag
  end
end
child(Allocation.warehouses => :warehouses) do
  attributes :id, :tag, :storekeeper, :place_id
end
