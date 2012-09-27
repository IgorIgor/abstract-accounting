# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

#TODO: проверить есть ли возможность что стронированный ресурс будет с не актуальным балансом
#TODO: вынести в модуль Warehouse

class WarehouseResourceReport
  WAYBILL_SIDE = Waybill.name
  ALLOCATION_SIDE = Allocation.name

  attr_reader :date, :entity, :amount, :state, :side, :document_id, :item_id

  def initialize(attrs)
    @date = attrs[:date]
    @entity = attrs[:entity]
    @amount = attrs[:amount]
    @state = attrs[:state]
    @side = attrs[:side]
    @document_id = attrs[:document_id]
    @item_id = Converter.int(attrs[:item_id])
  end

  class << self
    def all(args)
      state = 0.0
      scope = scope(args).order_by("created ASC, state DESC")
      if args[:page] && args[:per_page]
        if args[:page].to_i > 1
          #need refactoring
          state = scope(args).limit(args[:per_page] * (args[:page].to_i - 1)).select("state").
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
                 side: resource.side,
                 document_id: resource.document_id,
                 item_id: resource.item_id)
      end
    end

    def count(args)
      scope(args).count
    end

    def total(args)
      warehouse = Warehouse.all(where: { warehouse_id: { equal: args[:warehouse_id] },
                             'assets.id' => { equal_attr: args[:resource_id] } }).
          first
      warehouse ? warehouse.real_amount : 0.0
    end

    def scope(args)
      fact_scope = Fact.
                where{(resource_id == my{args[:resource_id]}) & (resource_type == Asset.name)}

      reverted_waybills_ids = fact_scope.joins{parent.to.waybill}.
          where{parent.amount == -1.0}.select{parent.to.waybill.id}

      waybills_scope = fact_scope.
                joins{parent.to.take}.
                joins{parent.to.waybill}.
                joins{from}.
                where{parent.to.take.place_id == my{args[:warehouse_id]}}.
                where{parent.amount == 1.0}.
                where{parent.to.waybill.id.not_in(reverted_waybills_ids)}.
                select{parent.to.waybill.created}.select{amount}.select{amount.as(:state)}.
                select{from.entity_id}.select{from.entity_type}.
                select("'#{WAYBILL_SIDE}' as side").
                select{parent.to.waybill.document_id}.
                select{parent.to.waybill.id.as(:item_id)}

      reverted_allocation_ids = fact_scope.joins{parent.to.allocation}.
          where{parent.amount == -1.0}.select{parent.to.allocation.id}

      allocations_scope = fact_scope.
                joins{parent.to.give}.
                joins{parent.to.allocation}.
                joins{to}.
                where{parent.to.give.place_id == my{args[:warehouse_id]}}.
                where{parent.amount == 1.0}.
                where{parent.to.allocation.id.not_in(reverted_allocation_ids)}.
                select{parent.to.allocation.created}.
                select{amount}.select{(amount * -1.0).as(:state)}.
                select{to.entity_id}.select{to.entity_type}.
                select("'#{ALLOCATION_SIDE}' as side").
                select{cast(parent.to.allocation.id.as("character(100)")).as(:document_id)}.
                select{parent.to.allocation.id.as(:item_id)}

      SqlRecord.union(waybills_scope.to_sql, allocations_scope.to_sql)
    end
  end
end
