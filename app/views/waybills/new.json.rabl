# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@waybill => :waybill) do
  attributes :created, :state, :document_id, :warehouse_id
  node(:distributor_id) { nil }
  node(:distributor_place_id) { nil }
end
node(:can_apply) { @waybill.can_apply? }
node(:can_cancel) { @waybill.can_cancel? }
child(LegalEntity.new => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(Place.new => :distributor_place) { attributes :tag }
child([] => :items)
child(Waybill.warehouses => :warehouses) do
  attributes :id, :tag, :storekeeper
end
