# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @local.id }
child(@local => :local) do
  attributes :tag, :date, :catalog_id
  child(@local.catalog => :catalog) { attributes :id, :tag }
end
child(@local.catalog => :catalog) { attributes :id, :tag }
child(@local.items => :items) do
  attributes :amount
  node(:correct) { true }
  child(:price_list) do
    attributes :id
    child(:bo_m => :bom) do
      attributes :id, :uid
      child(:resource => :resource) do
        attributes :tag, :mu
      end
    end
  end
end
