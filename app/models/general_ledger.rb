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
    def scope(name, &filter)
      if block_given?
        define_method name do |*args|
          value = @current_scope.instance_exec *args, &filter
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

  scope :on_date do |date = nil|
    on_date(date.nil? ? Date.current : Date.parse(date))
  end

  scope :paginate do |attrs = {}|
    unless attrs[:page].nil?
      per_page = (!attrs[:per_page].nil? and attrs[:per_page].to_i) ||
          Settings.root.per_page.to_i
      limit(per_page).offset((attrs[:page].to_i - 1) * per_page)
    end
  end

  scope :all do |attrs = {}|
    all(attrs)
  end

  scope :count do
    count
  end

  scope :by_deal do |deal_id|
    fact_ids = Fact.where{(from_deal_id == deal_id) | (to_deal_id == deal_id)}.select(:id)
    children_fact_ids = Fact.where{parent_id.in(fact_ids)}.select(:id)
    joins{fact}.where{fact.id.in(children_fact_ids + fact_ids)}
  end

  scope :by_deals do |deal_ids|
    joins{fact}.where{fact.from_deal_id.in(deal_ids) | fact.to_deal_id.in(deal_ids)}
  end
end
