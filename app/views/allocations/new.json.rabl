# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@allocation => :allocation) do
  attributes :created, :state, :warehouse_id
  node(:foreman_id) { nil }
  node(:foreman_place_id) { |all| all.foreman_place_or_new.id }
end
node(:can_apply) { @allocation.can_apply? }
node(:can_cancel) { @allocation.can_cancel? }
child(Entity.new => :foreman) { attributes :tag }
child(@allocation.foreman_place_or_new => :foreman_place) { attributes :tag }
child([] => :items)
child(Allocation.warehouses => :warehouses) do
  attributes :id, :tag, :storekeeper, :place_id
end


