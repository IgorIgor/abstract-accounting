# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class PriceList < Base
    has_paper_trail

    validates_presence_of :date
    validates_uniqueness_of :date, :scope => [:bo_m_id, :catalog_id]
    belongs_to :bo_m, class_name: BoM
    has_many :items, class_name: Price
    belongs_to :catalog

    class << self
      def filing_items(array)
        new_array = []
        array.each do |item|
          new_array.push({ bo_m_element: { id: item.bo_m_element.id,
                                           uid: item.bo_m_element.uid,
                                           rate: item.bo_m_element.rate,
                                           resource_tag: item.bo_m_element.resource.tag,
                                           resource_mu: item.bo_m_element.resource.mu,
                                           price_rate: item.rate }})
        end
        new_array
      end
    end

    def item_by_element_type(type)
      self.items.joins{:bo_m_element}.where{ bo_m_element.element_type == type }
    end

    def build_items(elements)
      if elements[:builders]
        self.items.build(rate: elements[:builders][:rate],
                         bo_m_element_id: elements[:builders][:bo_m_element_id])
      end
      if elements[:machinist]
        self.items.build(rate: elements[:machinist][:rate],
                         bo_m_element_id: elements[:machinist][:bo_m_element_id])
      end
      if elements[:machinery]
        elements[:machinery].each do |item|
          self.items.build(rate: item[1][:bo_m_element][:price_rate],
                           bo_m_element_id: item[1][:bo_m_element][:id])
        end
      end
      if elements[:resources]
        elements[:resources].each do |item|
          self.items.build(rate: item[1][:bo_m_element][:price_rate],
                           bo_m_element_id: item[1][:bo_m_element][:id])
        end
      end
    end
  end
end
