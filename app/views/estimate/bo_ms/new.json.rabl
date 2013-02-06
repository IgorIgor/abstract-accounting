# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@bo_m => :bo_m) do
  attributes :uid, :resource_id, :amount, :workers_amount, :avg_work_level, :drivers_amount
end
child(Asset.new => :resource) do
  attributes :tag, :mu
end
child(@bo_m.machinery => :machinery)
child(@bo_m.materials => :materials)
