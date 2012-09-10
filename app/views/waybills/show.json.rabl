# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
node(:id) { @waybill.id }
node(:type) { @waybill.class.name }
child(@waybill => :waybill) do
  attributes :document_id, :state, :warehouse_id
  node(:created) { |waybill| waybill.created.strftime("%m/%d/%Y") }
  glue @waybill.distributor do
    attributes :id => :distributor_id
  end
  glue @waybill.distributor_place do
    attributes :id => :distributor_place_id
  end
end
node(:can_apply) { @waybill.can_apply? }
node(:can_cancel) { @waybill.can_cancel? }
child(@waybill.distributor => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(@waybill.distributor_place => :distributor_place) { attributes :tag }
child(@waybill.items => :items) do
  attributes :amount, :price
  glue :resource do
    attributes :tag, :mu
  end
end
child(Waybill.warehouses => :warehouses) do
  attributes :id, :tag, :storekeeper
end
