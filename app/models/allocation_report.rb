# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class AllocationReport < Allocation
  def self.select_all
    self.select("allocations.*").
        select{deal.rules.from.give.resource.id.as('resource_id')}.
        select{deal.rules.from.give.resource.tag.as('resource_tag')}.
        select{deal.rules.from.give.resource.mu.as('resource_mu')}.
        select{(deal.rules.rate).as('resource_amount')}
  end

  def self.with_resources
    self.joins{deal.rules.from.give.resource(Asset)}
  end

  custom_sort(:foreman) do |dir|
    query = "entities.tag"
    joins{deal.rules.to.entity(Entity)}.order("#{query} #{dir}")
  end

  custom_sort(:resource_tag) do |dir|
    query = "assets.tag"
    joins{deal.rules.from.take.resource(Asset)}.order("#{query} #{dir}")
  end

  custom_sort(:resource_mu) do |dir|
    query = "assets.mu"
    joins{deal.rules.from.take.resource(Asset)}.order("#{query} #{dir}")
  end

  custom_sort(:resource_amount) do |dir|
    query = "rules.rate"
    joins{deal.rules}.order("#{query} #{dir}")
  end

  custom_search(:foreman) do |value|
    joins{deal.rules.to.entity(Entity)}.
        where{lower(deal.rules.to.entity.tag).like(lower("%#{value}%"))}
  end

  custom_search(:resource_tag) do |value|
    joins{deal.rules.from.give.resource(Asset)}.
        where{lower(deal.rules.from.give.resource.tag).like(lower("%#{value}%"))}
  end

  custom_search(:states) do |filter = {}|
    group_by = '"assets"."id", "assets"."tag", "assets"."mu", "rules"."rate"'
    scope = super(filter)
    scope = scope.group{group_by} unless scope.group_values.empty?
    scope
  end
end
