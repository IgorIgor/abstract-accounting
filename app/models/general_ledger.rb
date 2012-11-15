# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GeneralLedger
  class << self
    def scope(name, unscoped = false, &filter)
      if block_given?
        define_method name do |*args|
          if unscoped
            value = filter.call(*args)
          else
            value = @current_scope.instance_exec *args, &filter
          end
          if value.instance_of?(ActiveRecord::Relation)
            ledger_scope = clone
            ledger_scope.instance_variable_set(:@current_scope, value)
            ledger_scope
          else
            value
          end
        end
        define_singleton_method name do |*args|
          self.new.send(name, *args)
        end
      end
    end
  end

  def initialize
    @current_scope = Txn
  end

  scope :filtrate do |*args|
    filtrate(*args)
  end

  scope :sort do |*args|
    sort(*args)
  end

  scope :on_date do |date = nil|
    on_date(date.nil? ? Date.today : Date.parse(date))
  end

  scope :paginate do |*args|
    paginate(*args)
  end

  scope :all do |attrs = {}|
    all(attrs)
  end

  scope :count do
    count
  end

  scope :by_deals do |deal_ids|
    fact_ids = Fact.where{from_deal_id.in(deal_ids) | to_deal_id.in(deal_ids)}.select(:id)
    child_fact_ids = Fact.where{parent_id.in(fact_ids)}.select(:id)
    joins{fact}.where{fact.id.in(child_fact_ids + fact_ids)}
  end

  scope(:by_deal, :unscoped) do |deal_id|
    by_deals([deal_id])
  end
end
