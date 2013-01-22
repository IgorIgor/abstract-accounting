# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@price => :price) do
  attributes :date, :bo_m_id, :uid, :tag, :mu, :direct_cost, :workers_cost,
             :machinery_cost, :drivers_cost, :materials_cost
end
