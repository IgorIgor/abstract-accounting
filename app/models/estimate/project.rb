# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Project < Base
    validates_presence_of :place_id, :customer_id, :customer_type
    belongs_to :customer, :polymorphic => true
    belongs_to :place

    custom_sort(:customer_tag) do |dir|
      query = "case customer_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
      joins{customer(Entity).outer}.joins{customer(LegalEntity).outer}.order("#{query} #{dir}")
    end

    custom_sort(:place_tag) do |dir|
      joins{place}.order("places.tag #{dir}")
    end
  end
end
