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
  attributes :state,
             :foreman_id, :foreman_place_id,
             :storekeeper_id, :storekeeper_place_id
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
