# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object @estimate
attributes :object, :legal_entity, :boms
node :object do |item|
  {
    :id => item.id,
    :legal_entity_id => item.legal_entity_id,
    :catalog_id => item.catalog_id,
    :catalog_tag => item.catalog.tag,
    :date => item.date.strftime("%Y-%m-%d")
  }
end
node :legal_entity do |item|
  {
    :name => item.legal_entity.name,
    :identifier_name => item.legal_entity.identifier_name,
    :identifier_value => item.legal_entity.identifier_value
  }
end
node :boms do |item|
  item.items.map do |i|
    {
      :id => i.bom_id,
      :tag => i.bom.resource.tag,
      :tab => i.bom.tab,
      :count => i.amount,
      :sum => i.bom.sum_by_catalog(item.catalog, item.date, i.amount)
    }
  end
end
