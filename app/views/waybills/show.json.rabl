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
  attributes :document_id, :state
  node(:created) { |waybill| waybill.created.strftime("%m/%d/%Y") }
  node(:storekeeper_id) do |waybill|
    waybill.storekeeper.nil? ? nil : waybill.storekeeper.id
  end
  node(:storekeeper_place_id) do |waybill|
    waybill.storekeeper_place.nil? ? nil : waybill.storekeeper_place.id
  end
  node(:distributor_id) do |waybill|
    waybill.distributor.nil? ? nil : waybill.distributor.id
  end
  node(:distributor_place_id) do |waybill|
    waybill.distributor_place.nil? ? nil : waybill.distributor_place.id
  end
end
node(:can_apply) do
  @waybill.state == Statable::INWORK
end
node(:can_cancel) do
  @waybill.state == Statable::APPLIED || @waybill.state == Statable::INWORK
end
child(@waybill.distributor => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(@waybill.distributor_place => :distributor_place) { attributes :tag }
child(@waybill.storekeeper => :storekeeper) { attributes :tag }
child(@waybill.storekeeper_place => :storekeeper_place) { attributes :tag }
child(@waybill.items => :items) do
  attributes :amount, :price
  glue :resource do
    attributes :tag, :mu
  end
end
