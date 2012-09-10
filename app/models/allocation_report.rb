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

  def self.order_by(attrs = {})
    field = nil
    ordered = false
    scope = self
    case attrs[:field]
      when 'foreman'
        scope = scope.joins{deal.rules.to.entity(Entity)}
        field = 'entities.tag'
      when 'resource_tag'
        scope = scope.joins{deal.rules.from.give.resource}
        field = 'resource_tag'
      when 'resource_mu'
        scope = scope.joins{deal.rules.from.give.resource}
        field = 'resource_mu'
      when 'resource_amount'
        scope = scope.joins{deal.rules}
        field = 'resource_amount'
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

  def self.search(attrs = {})
    filtered = false
    scope = attrs.keys.inject(scoped) do |mem, key|
      case key.to_s
        when 'foreman'
          mem.joins{deal.rules.to.entity(Entity)}
        when 'resource_tag'
          mem.joins{deal.rules.from.give.resource(Asset)}
        else
          filtered = true
          super(attrs)
      end
    end
    unless filtered
      scope = attrs.inject(scope) do |mem, (key, value)|
        if key == 'foreman'
          mem.where{lower(deal.rules.to.entity.tag).like(lower("%#{value}%"))}
        elsif key == 'resource_tag'
          mem.where{lower(deal.rules.from.give.resource.tag).like(lower("%#{value}%"))}
        end
      end
    end
    scope
  end
end
