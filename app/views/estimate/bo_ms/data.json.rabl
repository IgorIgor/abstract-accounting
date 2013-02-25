# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@bo_ms => :objects) do
  attributes :id, :uid, :amount, :workers_amount, :avg_work_level, :drivers_amount
  child(:resource => :resource) { attributes :tag, :mu }
  child(:catalog => :catalog) { attributes :tag }
  child(:machinery => :machinery) do
    attributes :uid, :resource_id, :amount
    child(:resource => :resource) do
      attributes :tag, :mu
    end
  end
  child(:materials => :materials) do
    attributes :uid, :resource_id, :amount
    child(:resource => :resource) do
      attributes :tag, :mu
    end
  end
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
