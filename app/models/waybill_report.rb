# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillReport < Waybill
  def self.select_all
    self.select("waybills.*").
        select{deal.rules.from.take.resource.id.as('resource_id')}.
        select{deal.rules.from.take.resource.tag.as('resource_tag')}.
        select{deal.rules.from.take.resource.mu.as('resource_mu')}.
        select{(deal.rules.from.rate).as('resource_price')}.
        select{(deal.rules.rate).as('resource_amount')}.
        select{(deal.rules.rate / deal.rules.from.rate).as('resource_sum')}
  end

  def self.with_resources
    self.joins{deal.rules.from.take.resource(Asset)}
  end

  def self.order_by(attrs = {})
    field = nil
    ordered = false
    scope = self
    case attrs[:field]
      when 'distributor'
        scope = scope.joins{deal.rules.from.entity(LegalEntity)}
        field = 'legal_entities.name'
      when 'resource_tag'
        scope = scope.joins{deal.rules.from.take.resource}
        field = 'resource_tag'
      when 'resource_mu'
        scope = scope.joins{deal.rules.from.take.resource}
        field = 'resource_mu'
      when 'resource_amount'
        scope = scope.joins{deal.rules}
        field = 'resource_amount'
      when 'resource_price'
        scope = scope.joins{deal.rules.from}
        field = 'resource_price'
      when 'resource_sum'
        scope = scope.joins{deal.rules.from}
        field = 'resource_sum'
      else
        scope = super(attrs)
        ordered = true
    end
    unless ordered & field.nil?
      if attrs[:type] == 'desc'
        scope = scope.order("#{field} DESC")
      else
        scope = scope.order(field)
      end
    end
    scope
  end

  custom_search(:distributor) do |value|
    joins{deal.rules.from.entity(LegalEntity)}.
        where{lower(deal.rules.from.entity.name).like(lower("%#{value}%"))}
  end

  custom_search(:resource_tag) do |value|
    joins{deal.rules.from.take.resource(Asset)}.
        where{lower(deal.rules.from.take.resource.tag).like(lower("%#{value}%"))}
  end

  def self.search_by_states(filter = {})
    statable_search(filter)
    group_by = '"assets"."id", "assets"."tag", "assets"."mu", "froms_rules"."rate", "rules"."rate"'
    scope = statable_search(filter)
    scope = scope.group{group_by} unless scope.group_values.empty?
    scope
  end
end
