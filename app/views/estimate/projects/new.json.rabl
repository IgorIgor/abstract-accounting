# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@project => :project) do
  attributes :place_id, :customer_id
  node(:customer_type) { LegalEntity.name }
  child(Place.new => :place) do
    attributes :tag
  end
  child(Estimate::Catalog.new => :boms_catalog) { attributes :id, :tag }
  child(Estimate::Catalog.new => :prices_catalog) { attributes :id, :tag }
  child(LegalEntity.new => :legal_entity) do
    attributes :tag, :identifier_value
  end
  child(Entity.new => :entity) do
    attributes :tag
  end
end
