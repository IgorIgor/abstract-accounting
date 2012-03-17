# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object @waybill
node :object do |waybill|
  {
    id: waybill.id,
    document_id: waybill.document_id,
    distributor_id: waybill.distributor_id,
    distributor_place_id: waybill.distributor_place_id,
    storekeeper_id: waybill.storekeeper_id,
    storekeeper_place_id: waybill.storekeeper_place_id,
    created: waybill.created.strftime("%m/%d/%Y")
  }
end
node :distributor do |waybill|
  {
    name: waybill.distributor.name,
    identifier_name: waybill.distributor.identifier_name,
    identifier_value: waybill.distributor.identifier_value
  }
end
node :distributor_place do |waybill|
  {
    tag: waybill.distributor_place.tag
  }
end
node :storekeeper do |waybill|
  {
    tag: waybill.storekeeper.tag
  }
end
node :storekeeper_place do |waybill|
  {
    tag: waybill.storekeeper_place.tag
  }
end
node :items do |waybill|
  waybill.items.map do |i|
    {
      :tag => i.resource.tag,
      :mu => i.resource.mu,
      :amount => i.amount,
      :price => i.price
    }
  end
end
