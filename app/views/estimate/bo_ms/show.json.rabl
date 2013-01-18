# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @bo_m.id }
child(@bo_m => :bo_m) do
  attributes :uid, :resource_id, :amount, :workers_amount, :avg_work_level, :drivers_amount,
             :catalog_id
end
child(@bo_m.resource => :resource) do
  attributes :tag, :mu
end
child(@bo_m.catalog => :catalog) do
  attributes :tag
end
child(@bo_m.machinery => :machinery) do
  attributes :uid, :resource_id, :amount
  child(:resource => :resource) do
    attributes :tag, :mu
  end
end
child(@bo_m.materials => :materials) do
  attributes :uid, :resource_id, :amount
  child(:resource => :resource) do
    attributes :tag, :mu
  end
end
