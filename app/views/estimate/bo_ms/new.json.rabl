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
  attributes :uid, :resource_id
end
child(Asset.new => :resource) do
  attributes :tag, :mu
end
child(Estimate::Catalog.new => :catalog) do
  attributes :id, :tag
end
child(Object.new => :elements) do
  child(Estimate::BoMElement.new => :builders) do
    attributes :rate
  end
  child(Estimate::BoMElement.new => :rank) do
    attributes :rate
  end
  child(Estimate::BoMElement.new => :machinist) do
    attributes :rate
  end
  child([] => :machinery)
  child([] => :resources)
end
