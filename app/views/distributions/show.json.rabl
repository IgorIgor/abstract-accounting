# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object @distribution
node :object do |distribution|
  {
    id: distribution.id,
    storekeeper_id: distribution.storekeeper_id,
    storekeeper_place_id: distribution.storekeeper_place_id,
    foreman_id: distribution.foreman_id,
    foreman_place_id: distribution.foreman_place_id,
    created: distribution.created.strftime("%m/%d/%Y"),
    state: distribution.state
  }
end
node :storekeeper do |distribution|
  {
    tag: distribution.storekeeper.tag
  }
end
node :storekeeper_place do |distribution|
  {
    tag: distribution.storekeeper_place.tag
  }
end
node :foreman do |distribution|
  {
    tag: distribution.foreman.tag
  }
end
node :foreman_place do |distribution|
  {
    tag: distribution.foreman_place.tag
  }
end
node :items do |distribution|
  distribution.items.map do |i|
    {
      :tag => i.resource.tag,
      :mu => i.resource.mu,
      :amount => i.amount
    }
  end
end
