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
  attributes :created, :state, :document_id
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
child(LegalEntity.new => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(Place.new => :distributor_place) { attributes :tag }
child((@waybill.storekeeper ? @waybill.storekeeper : Entity.new) => :storekeeper) do
  attributes :tag
end
place = @waybill.storekeeper_place
child((place ? place : Place.new) => :storekeeper_place) { attributes :tag }
child([] => :items)
