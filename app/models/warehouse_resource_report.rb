# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehouseResourceReport
  WAYBILL_SIDE = Waybill.name
  ALLOCATION_SIDE = Allocation.name

  attr_reader :date, :entity, :amount, :state, :side

  def initialize(attrs)
    @date = attrs[:date]
    @entity = attrs[:entity]
    @amount = attrs[:amount]
    @state = attrs[:state]
    @side = attrs[:side]
  end

  class << self
    def all(args)
      state = 0.0
      scope = scope(args).order_by("created ASC, state DESC")
      if args[:page] && args[:per_page]
        if args[:page] > 1
          #need refactoring
          state = scope(args).limit(args[:per_page] * (args[:page] - 1)).select("state").
              inject(0.0) do |mem, value|
            mem += value.state.to_f
          end
        end
        scope = scope.paginate(page: args[:page], per_page: args[:per_page])
      end
      scope.all.collect do |resource|
        state += resource.state.to_f
        self.new(date: DateTime.parse(resource.created),
                 amount: resource.amount.to_f,
                 state: state,
                 entity: resource.entity_type.constantize.find(resource.entity_id),
                 side: resource.side)
      end
    end

    def count(args)
      scope(args).count
    end

    def scope(args)
      fact_scope = Fact.
                where{(resource_id == my{args[:resource_id]}) & (resource_type == Asset.name)}

      waybills_scope = fact_scope.
                joins{parent.to.take}.
                joins{parent.to.waybill}.
                joins{from}.
                where{parent.to.take.place_id == my{args[:warehouse_id]}}.
                where{parent.amount == 1.0}.
                select{parent.to.waybill.created}.select{amount}.select{amount.as(:state)}.
                select{from.entity_id}.select{from.entity_type}.
                select("'#{WAYBILL_SIDE}' as side")

      allocations_scope = fact_scope.
                      joins{parent.to.give}.
                      joins{parent.to.allocation}.
                      joins{to}.
                      where{parent.to.give.place_id == my{args[:warehouse_id]}}.
                      where{parent.amount == 1.0}.
                      select{parent.to.allocation.created}.
                      select{amount}.select{(amount * -1.0).as(:state)}.
                      select{to.entity_id}.select{to.entity_type}.
                      select("'#{ALLOCATION_SIDE}' as side")

      SqlRecord.union(waybills_scope.to_sql, allocations_scope.to_sql)
    end
  end
end
