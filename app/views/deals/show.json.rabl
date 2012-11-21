# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @deal.id }
child(@deal => :deal) do
  attributes :tag, :isOffBalance, :rate, :entity_id, :entity_type, :compensation_period
  node(:execution_date) { @deal.execution_date.strftime('%Y/%m/%d') unless @deal.execution_date.nil? }
  child(@deal.limit => :limit_attributes) do
    node(:amount) { @deal.limit_amount }
    node(:side) { @deal.limit_side }
  end
end
child(@deal.entity => :entity) do
  node(:tag) do
    if @deal.entity_type == 'Entity'
      @deal.entity.tag
    elsif @deal.entity_type == 'LegalEntity'
      @deal.entity.name
    end
  end
end
child(@deal.give => :give) do
  attributes :resource_id, :resource_type, :place_id
  child(:resource => :resource) do
    node(:tag) do
      if @deal.give.resource_type == 'Asset'
        @deal.give.resource.tag
      elsif @deal.give.resource_type == 'Money'
        @deal.give.resource.alpha_code
      end
    end
  end
  child(:place => :place) { attributes :tag }
end
child(@deal.take => :take) do
  attributes :resource_id, :resource_type, :place_id
  child(:resource => :resource) do
    node(:tag) do
      if @deal.take.resource_type == 'Asset'
        @deal.take.resource.tag
      elsif @deal.take.resource_type == 'Money'
        @deal.take.resource.alpha_code
      end
    end
  end
  child(:place => :place) { attributes :tag }
end
child(@deal.rules => :rules) do
  attributes :rate, :fact_side, :change_side, :from_id, :to_id
  child(:from => :from) { attributes :tag }
  child(:to => :to) { attributes :tag }
end
