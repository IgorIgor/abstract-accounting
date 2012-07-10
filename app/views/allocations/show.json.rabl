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
  node(:created) { |allocation| allocation.created.strftime("%m/%d/%Y") }
  attributes :id, :state, :foreman_id, :foreman_place_id
  node(:storekeeper_id) do |waybill|
    waybill.storekeeper.nil? ? nil : waybill.storekeeper.id
  end
  node(:storekeeper_place_id) do |waybill|
    waybill.storekeeper_place.nil? ? nil : waybill.storekeeper_place.id
  end
end
node(:can_apply) do
  @allocation.state == Statable::INWORK
end
node(:can_cancel) do
  @allocation.state == Statable::APPLIED || @allocation.state == Statable::INWORK
end
child(@allocation.storekeeper => :storekeeper) { attributes :tag }
child(@allocation.storekeeper_place => :storekeeper_place) { attributes :tag }
child(@allocation.foreman => :foreman) { attributes :tag }
child(@allocation.foreman_place => :foreman_place) { attributes :tag }
child(@allocation.items => :items) do
  attributes :amount
  glue :resource do
    attributes :mu, :tag
  end
end
