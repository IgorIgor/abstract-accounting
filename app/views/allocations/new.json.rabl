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
  attributes :created, :state,
             :foreman_id, :foreman_place_id,
             :storekeeper_id, :storekeeper_place_id
end
child(Entity.new => :foreman) { attributes :tag }
child(@allocation.build_foreman_place => :foreman_place) { attributes :tag }
storekeeper = @allocation.storekeeper
child(storekeeper ? storekeeper : Entity.new => :storekeeper) { attributes :tag }
place = @allocation.storekeeper_place
place = @allocation.build_storekeeper_place unless place
child(place => :storekeeper_place) { attributes :tag }
child([] => :items)

