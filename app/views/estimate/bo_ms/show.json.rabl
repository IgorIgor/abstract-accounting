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
  attributes :uid, :resource_id, :id
end
child(@bo_m.resource => :resource) do
  attributes :tag, :mu
end
child(Object.new => :elements) do
  child(@bo_m.builders[0] || Estimate::BoMElement.new => :builders) do
    attributes :rate
  end
  child(@bo_m.rank[0] || Estimate::BoMElement.new => :rank) do
    attributes :rate
  end
  child(@bo_m.machinist[0] || Estimate::BoMElement.new => :machinist) do
    attributes :rate
  end
  child(@bo_m.machinery => :machinery) do
    attributes :rate
    node(:code) { |el| el.uid }
    node(:id) { |el| el.resource_id }
    node(:tag) { |el| el.resource.tag }
    node(:mu) { |el| el.resource.mu }
  end
  child(@bo_m.resources => :resources) do
    attributes :rate
    node(:code) { |el| el.uid }
    node(:id) { |el| el.resource_id }
    node(:tag) { |el| el.resource.tag }
    node(:mu) { |el| el.resource.mu }
  end
end
