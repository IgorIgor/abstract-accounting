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
  node(:distributor_type) { LegalEntity.name }
  node(:distributor_place_id) { nil }
end
node(:owner) { @waybill.owner? }
node(:state) do
  partial "state/can_do", :object => @waybill
end
child(LegalEntity.new => :legal_entity) do
  attributes :name, :identifier_value
  node(:identifier_name) { "VATIN" }
end
child(Entity.new => :entity) do
  attributes :tag
end
child(Place.new => :distributor_place) do
  node(:tag) { I18n.t('views.waybills.defaults.distributor.place') }
end
child([] => :items)
child(Waybill.warehouses => :warehouses) do
  attributes :id, :tag, :storekeeper
end
