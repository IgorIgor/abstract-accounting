# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object @waybill
attributes :document_id, :distributor_id, :distributor_place_id, :storekeeper_id,
           :storekeeper_place_id

node(:created) { |waybill| waybill.created.strftime("%m/%d/%Y") }
node(:distributor) { |waybill|
  {
    name: waybill.distributor.name,
    identifier_name: waybill.distributor.identifier_name,
    identifier_value: waybill.distributor.identifier_value
  }
}
node(:distributor_place) { |waybill| { tag: waybill.distributor_place.tag }}
node(:storekeeper) { |waybill| { tag: waybill.storekeeper.tag }}
node(:storekeeper_place) { |waybill| { tag: waybill.storekeeper_place.tag }}

node(:items) { |waybill|
  waybill.items.map { |i|
    { tag: i.resource.tag, mu: i.resource.mu, amount: i.amount, price: i.price }
  }
}
