# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehouseForemanReport
  attr_reader :resource, :amount

  def initialize(attrs)
    @resource = attrs[:resource]
    @amount = Converter.float(attrs[:amount])
  end

  class << self
    def foremen(warehouse_id)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      Allocation.joins{deal.give}.where{deal.give.place_id == warehouse_id}.
          joins{deal.to_facts}.
          joins{deal.deal_state}.where{deal.deal_state.closed != nil}.
          where{deal.id.not_in(reversed_scope)}.
          joins{deal.rules.to}.select{deal.rules.to.entity_id}.
          select{deal.rules.to.entity_type}.uniq.
          all.collect { |al| al.entity_type.constantize.find(al.entity_id) }
    end

    def all(args)
      scope = scoped(args)

      if args[:page] && args[:per_page] && args[:page].to_i > 0 && args[:per_page].to_i > 0
        scope = scope.limit(args[:per_page]).
            offset(args[:per_page].to_i * (args[:page].to_i - 1))
      end

      scope.select{resource_id}.select{resource_type}.select{sum(amount).as(:amount)}.
          includes(:resource).collect do |fact|
        WarehouseForemanReport.new(resource: fact.resource, amount: fact.amount)
      end
    end

    def count(args)
      SqlRecord.from(scoped(args).select{resource_id}.to_sql).count
    end

    private
    def scoped(args)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.give}.where{parent.to.give.place_id == my{args[:warehouse_id]}}.
                joins{to}.joins{parent.to.allocation}.
                where{parent.to_deal_id.not_in(reversed_scope)}.
                where{(to.entity_id == my{args[:foreman_id]}) & (to.entity_type == Entity.name)}

      if args[:start] && args[:stop]
        scope = scope.where{parent.to.allocation.created >= my{args[:start].beginning_of_day}}.
                      where{parent.to.allocation.created <= my{args[:stop].end_of_day}}
      end
      scope.group{resource_id}.group{resource_type}
    end
  end
end
