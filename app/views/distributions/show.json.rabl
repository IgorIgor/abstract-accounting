# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@distribution => :distribution) do
  node(:created) { |distribution| distribution.created.strftime("%m/%d/%Y") }
  attributes :id, :state,
             :foreman_id, :foreman_place_id,
             :storekeeper_id, :storekeeper_place_id
end
child(@distribution.storekeeper => :storekeeper) { attributes :tag }
child(@distribution.storekeeper_place => :storekeeper_place) { attributes :tag }
child(@distribution.foreman => :foreman) { attributes :tag }
child(@distribution.foreman_place => :foreman_place) { attributes :tag }
child(@distribution.items => :items) do
  attributes :amount
  glue :resource do
    attributes :mu, :tag
  end
end
