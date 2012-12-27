# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehouseForemanReport
  attr_reader :resource, :amount, :price

  def initialize(attrs)
    @resource = attrs[:resource]
    @amount = Converter.float(attrs[:amount])
    @price = Converter.float(attrs[:price])
  end

  def sum
    @amount * @price
  end

  class << self
    def foremen(warehouse_id)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      Allocation.joins{deal.give}.where{{deal.give => sift(:by_resource, warehouse_id)}}.
          joins{deal.to_facts}.
          joins{deal.deal_state}.where{{deal => sift(:opened)}}.
          without_deal_id(reversed_scope).
          joins{deal.rules.to}.select{deal.rules.to.entity_id}.
          select{deal.rules.to.entity_type}.uniq.
          all.collect { |al| al.entity_type.constantize.find(al.entity_id) }
    end

    def all(args)
      scope = scoped(args)

      if args[:page] && args[:per_page] && args[:page].to_i > 0 && args[:per_page].to_i > 0
        scope = scope.paginate(page:args[:page].to_i, per_page: args[:per_page].to_i)
      end

      if args[:resource_ids] && !args[:resource_ids].nil?
        scope = scope.by_resources(args[:resource_ids].split(','))
      end

      if args[:sort]
        if args[:sort][:field] == 'tag'
          scope = scope.joins{resource(Asset)}.group{resource.tag}.
                        order("assets.tag #{args[:sort][:type]}")
        elsif args[:sort][:field] == 'mu'
          scope = scope.joins{resource(Asset)}.group{resource.mu}.
                        order("assets.mu #{args[:sort][:type]}")
        elsif args[:sort][:field] == 'amount'
          scope = scope.order{sum(amount).__send__(args[:sort][:type].downcase)}
        end
      end

      prices = prices_scoped_with_range(args).
          joins{from.take}.where{from.take.resource_id.in(scope.select{resource_id})}.
          select{resource_id}.select{resource_type}.
          select{(sum(facts.amount / from.rate) / sum(facts.amount)).as(:price)}.all

      prices_before = nil

      scope.select{resource_id}.select{resource_type}.select{sum(amount).as(:amount)}.
          includes(:resource).collect do |fact|
        price = 1.0
        price_obj = prices.select do |item|
          item.resource_id == fact.resource_id && item.resource_type == fact.resource_type
        end[0]
        if price_obj
          price = price_obj.price
        else
          unless prices_before
            prices_before = prices_scoped_before(args).
                joins{from.take}.where{from.take.resource_id.in(scope.select{resource_id})}.
                select{resource_id}.select{resource_type}.
                select{(max(parent.to.waybill.id)).as(:waybill_id)}.all
          end
          price_item = prices_before.select do |item|
            item.resource_id == fact.resource_id && item.resource_type == fact.resource_type
          end[0]

          price_obj = Waybill.where{id == price_item.waybill_id}.
              joins{deal.rules.from.take}.
              where{deal.rules.from.take.resource_id == fact.resource_id}.
              select{deal.rules.from.rate.as(:price)}.first
          price = (1.0 / Converter.float(price_obj.price))
        end
        WarehouseForemanReport.new(resource: fact.resource, amount: fact.amount,
                                   price: Converter.float(price).accounting_norm)
      end
    end

    def count(args)
      SqlRecord.from(scoped(args).select{resource_id}.to_sql).count
    end

    private
    def scoped(args)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.give}.where{{parent.to.give => sift(:by_resource, args[:warehouse_id])}}.
                joins{to}.joins{parent.to.allocation}.
                where{{parent => sift(:without_to_deal_ids, reversed_scope)}}.
                where{{to => sift(:by_entity, args[:foreman_id], Entity.name)}}

      if args[:start] && args[:stop]
        scope = scope.where{{parent.to.allocation => sift(:date_range, args[:start], args[:stop])}}
      end

      if args[:search]
        scope = args[:search].inject(scope) do |mem, (key, value)|
          case key.to_s
            when 'tag'
              mem.joins{resource(Asset)}.where{lower(resource.tag).like(lower("%#{value}%"))}
            when 'mu'
              mem.joins{resource(Asset)}.where{lower(resource.mu).like(lower("%#{value}%"))}
            when 'amount'
              mem.having{sum(amount) == value}
            else
              mem.where{lower(__send__(key)).like(lower("%#{value}%"))}
          end
        end
      end

      scope.group{resource_id}.group{resource_type}
    end

    def prices_scoped_with_range(args)
      reversed_scope  = Waybill.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.take}.where{{parent.to.take => sift(:by_resource, args[:warehouse_id])}}.
                joins{parent.to.waybill}.
                where{{parent => sift(:without_to_deal_ids, reversed_scope)}}
      if args[:start] && args[:stop]
        scope = scope.where{{parent.to.waybill => sift(:date_range, args[:start], args[:stop])}}
      end
      scope.group{resource_id}.group{resource_type}
    end

    def prices_scoped_before(args)
      reversed_scope  = Waybill.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.take}.where{{parent.to.take => sift(:by_resource, args[:warehouse_id])}}.
                joins{parent.to.waybill}.
                where{{parent => sift(:without_to_deal_ids, reversed_scope)}}
      if args[:start] && args[:stop]
        scope = scope.where{{parent.to.waybill => sift(:date_range, DateTime.new(1), args[:start])}}
      end
      scope.group{resource_id}.group{resource_type}
    end
  end
end
