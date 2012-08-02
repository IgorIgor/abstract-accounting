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
  attributes :created, :state
  node(:storekeeper_id) do |allocation|
    allocation.storekeeper.nil? ? nil : allocation.storekeeper.id
  end
  node(:storekeeper_place_id) do |allocation|
    allocation.storekeeper_place.nil? ? nil : allocation.storekeeper_place.id
  end
  node(:foreman_id) do |allocation|
    allocation.foreman.nil? ? nil : allocation.foreman.id
  end
  node(:foreman_place_id) do |allocation|
    allocation.foreman_place.nil? ? nil : allocation.foreman_place.id
  end
end
node(:can_apply) do
  @allocation.state == Statable::INWORK
end
node(:can_cancel) do
  @allocation.state == Statable::APPLIED || @allocation.state == Statable::INWORK
end
child(Entity.new => :foreman) { attributes :tag }
storekeeper = @allocation.storekeeper
child(storekeeper ? storekeeper : Entity.new => :storekeeper) { attributes :tag }
place = @allocation.storekeeper_place
child((place ? place : Place.new) => :storekeeper_place) { attributes :tag }
child((place ? place : Place.new) => :foreman_place) { attributes :tag }
child([] => :items)

