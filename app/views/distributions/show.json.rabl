# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object @distribution
attributes :foreman_id, :foreman_place_id, :storekeeper_id,
           :storekeeper_place_id, :state

node(:created) { |distribution| distribution.created.strftime("%m/%d/%Y") }
node(:storekeeper) { |distribution| { tag: distribution.storekeeper.tag }}
node(:storekeeper_place) { |distribution| { tag: distribution.storekeeper_place.tag }}
node(:foreman) { |distribution| { tag: distribution.foreman.tag }}
node(:foreman_place) { |distribution| { tag: distribution.foreman_place.tag }}

node(:items) { |distribution|
  distribution.items.map { |i|
    { tag: i.resource.tag, mu: i.resource.mu, amount: i.amount }
  }
}
