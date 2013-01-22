# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@price_list => :price_list) do
  attributes :date, :bo_m_id
end
child(Asset.new => :resource) do
  attributes :tag, :mu
end
child(Object.new => :elements) do
  child(Estimate::Price.new => :builders) do
    attributes :rate, :bo_m_element_id
    node(:bo_m_element_rate) {}
  end
  child(Estimate::Price.new => :machinist) do
    attributes :rate, :bo_m_element_id
    node(:bo_m_element_rate) {}
  end
  node(:rank_rate) {}
  node(:machinery) {[]}
  node(:machinery_length) {0}
  node(:resources) {[]}
  node(:resources_length) {0}
end
