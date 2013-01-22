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
  attributes :date, :bo_m_id, :id
  node(:uid) { @price_list.bo_m.uid }
end
child(@price_list.bo_m.resource => :resource) do
  attributes :tag, :mu
end
child(Object.new => :elements) do
  child(@price_list.item_by_element_type(Estimate::BoM::BUILDERS)[0] || Estimate::Price.new => :builders) do
    attributes :rate, :bo_m_element_id
    node(:bo_m_element_rate) { |price| price.bo_m_element.try(:rate) }
  end
  node(:rank_rate) { @price_list.bo_m.rank[0].try(:rate) }
  child(@price_list.item_by_element_type(Estimate::BoM::MACHINIST)[0] || Estimate::Price.new => :machinist) do
    attributes :rate, :bo_m_element_id
    node(:bo_m_element_rate) { |price| price.bo_m_element.try(:rate) }
  end
  node(:machinery) { Estimate::PriceList.filing_items(@price_list.item_by_element_type(Estimate::BoM::MACHINERY)) }
  node(:machinery_length) { @price_list.bo_m.machinery.length }
  node(:resources) { Estimate::PriceList.filing_items(@price_list.item_by_element_type(Estimate::BoM::RESOURCES)) }
  node(:resources_length) { @price_list.bo_m.resources.length }
end
