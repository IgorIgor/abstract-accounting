# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class BalanceSheet < Array
  class << self
    def filter_attr(name, options = {})
      define_method "#{name}_value" do
        value = self.instance_variable_get("@#{name}".to_sym)
        if value
          value
        elsif options[:default]
          options[:default]
        end
      end
      define_method name do |value = nil|
        self.instance_variable_set("@#{name}".to_sym, value)
        self
      end
      define_singleton_method name do |value = nil|
        self.new.send(name, value)
      end
    end

    def getter(name, &block)
      define_method name, &block
      define_singleton_method name do |*attrs|
        self.new.send(name, *attrs)
      end
    end
  end

  filter_attr :date, default: DateTime.now
  filter_attr :paginate
  filter_attr :resource
  filter_attr :entity
  filter_attr :place_id
  filter_attr :group_by
  filter_attr :search
  filter_attr :order

  getter :all do |options = {}|
    build_scopes
    if self.resource_value || self.entity_value || self.place_id_value || self.search_value || self.order_value
      scope = @balance_scope
      scope = sort(scope) if self.order_value
      scope = scope.paginate(self.paginate_value) if self.paginate_value
      scope.all(options).each do |o|
        self << o
      end
    elsif self.group_by_value
      scope = SqlRecord
      scope = scope.paginate(self.paginate_value) if self.paginate_value
      scope = scope.from(@balance_scope.to_sql)
      select = "*"
      case self.group_by_value
        when 'place'
          scope = scope.join("INNER JOIN places ON places.id = T.group_id")
          select = "T.group_id, places.tag AS group_column, 'Place' AS group_type"
        when 'resource'
          scope = scope.join("LEFT JOIN assets ON T.group_id = assets.id AND T.group_type = 'Asset'").
                        join("LEFT JOIN money ON T.group_id = money.id AND T.group_type = 'Money'")
          select = "T.group_id, CASE WHEN T.group_type='Asset' THEN assets.tag ELSE money.alpha_code END AS group_column, T.group_type"
        when 'entity'
          scope = scope.
              join("LEFT JOIN entities on T.group_id = entities.id AND T.group_type = 'Entity'").
              join("LEFT JOIN legal_entities on T.group_id = legal_entities.id AND T.group_type = 'LegalEntity'")
          select = "T.group_id, CASE WHEN T.group_type='Entity' THEN entities.tag ELSE legal_entities.name END AS group_column, T.group_type"
      end
      scope.select(select).each do |object|
        self << object
      end
    else
      balance_ids = []
      income_ids = []
      scope = SqlRecord
      scope = scope.paginate(self.paginate_value) if self.paginate_value
      scope.union(@balance_scope.select("id, '#{Balance.name}' as type").to_sql,
                  @income_scope.select("id, '#{Income.name}' as type").to_sql).
            all.each do |object|
        if object.type == Balance.name
          balance_ids << object.id
        else
          income_ids << object.id
        end
      end
      self.concat(Balance.where{id.in(balance_ids)}.find(:all, options))
      self.concat(Income.where{id.in(income_ids)}.find(:all, options))
    end
    self
  end

  getter :db_count do
    build_scopes
    if self.resource_value || self.entity_value || self.place_id_value || self.group_by_value
      SqlRecord.from(@balance_scope.to_sql).count
    else
      SqlRecord.union(@balance_scope.select(:id).to_sql, @income_scope.select(:id).to_sql).
          count
    end
  end

  def initialize
    @assets_retrieved = false
    @assets = 0.0
    @liabilities = 0.0
    @balance_scope = Balance
    @income_scope = Income
    @scopes_updated = false
  end

  def assets
    retrieve_assets unless @assets_retrieved
    @assets
  end

  def liabilities
    retrieve_assets unless @assets_retrieved
    @liabilities
  end

  def sort(scope)
    if self.order_value[:field] == 'deal'
      scope = scope.joins{deal.outer}.order("deals.tag #{self.order_value[:type]}")
    elsif self.order_value[:field] == 'entity'
      query = "case entity_type
                              when 'Entity'      then entities.tag
                              when 'LegalEntity' then legal_entities.name
                         end"
      scope = scope.joins{deal.entity(Entity).outer}.
          joins{deal.entity(LegalEntity).outer}.
          order("#{query} #{self.order_value[:type]}")
    elsif self.order_value[:field] == 'resource'
      query = "case resource_type
                              when 'Asset' then assets.tag
                              when 'Money' then money.alpha_code
                         end"
      scope = scope.joins{give.resource(Asset).outer}.
          joins{give.resource(Money).outer}.                #only give?
          order("#{query} #{self.order_value[:type]}")
    elsif self.order_value[:field] == 'place'
      scope = scope.joins{give.place.outer}.
          joins{give.place.outer}.                            #only give?
          order("places.tag #{self.order_value[:type]}")
    end
    scope
  end

  protected
  def build_scopes
    unless @scopes_updated
      @balance_scope = @balance_scope.in_time_frame(self.date_value + 1, self.date_value)
      @income_scope = @income_scope.in_time_frame(self.date_value + 1, self.date_value)
      if self.resource_value
        @balance_scope = @balance_scope.joins(:take).joins(:give).
            with_resource(self.resource_value[:id], self.resource_value[:type])
      end
      if self.entity_value
        @balance_scope = @balance_scope.joins(:deal).
            with_entity(self.entity_value[:id], self.entity_value[:type])
      end
      if self.place_id_value
        @balance_scope = @balance_scope.joins(:take).joins(:give).
            with_place(self.place_id_value)
      end
      if self.search_value
        if self.search_value[:resource]
          @balance_scope = @balance_scope.joins{give.resource(Asset)}.
              where{lower(give.resource.tag).like(lower("%#{my{search_value[:resource]}}%"))}
        end
        if self.search_value[:place]
          @balance_scope = @balance_scope.joins{give.place}.joins{take.place}.
              where{((lower(give.place.tag).like(lower("%#{my{search_value[:place]}}%"))) &
              (side == Balance::PASSIVE)) |
              ((lower(take.place.tag).like(lower("%#{my{search_value[:place]}}%"))) &
                  (side == Balance::ACTIVE))}
        end
        if self.search_value[:entity]
          @balance_scope = @balance_scope.joins{deal.entity(Entity)}.
              where{lower(deal.entity.tag).like(lower("%#{my{search_value[:entity]}}%"))}
        end
      end
      if self.group_by_value
        case self.group_by_value
          when 'place'
            @balance_scope = @balance_scope.joins{deal.give}.
                select("terms.place_id AS group_id").group('terms.place_id')
          when 'resource'
            @balance_scope = @balance_scope.
                select("terms.resource_id AS group_id, terms.resource_type AS group_type").
                joins{deal.give}.
                group('terms.resource_id, terms.resource_type')
          when 'entity'
            @balance_scope = @balance_scope.
                select('deals.entity_id AS group_id, deals.entity_type AS group_type').
                joins{deal}.
                group('deals.entity_id, deals.entity_type')
        end
      end
      @scopes_updated = true
    end
  end

  def retrieve_assets
    build_scopes
    object = if self.resource_value || self.entity_value || self.place_id_value ||
        self.search_value
        SqlRecord.from(@balance_scope.select(build_select_statement(Balance)).to_sql).
                 select("SUM(assets) as assets, SUM(liabilities) as liabilities").first
      else
        SqlRecord.union(@balance_scope.select(build_select_statement(Balance)).to_sql,
                        @income_scope.select(build_select_statement(Income)).to_sql).
                  select("SUM(assets) as assets, SUM(liabilities) as liabilities").first
      end
    @assets = object.assets.to_f
    @liabilities = object.liabilities.to_f
    @assets_retrieved = true
  end

  def build_select_statement(klass)
    {assets: klass::ACTIVE, liabilities: klass::PASSIVE}.map do |key, value|
      "(CASE WHEN #{klass.name.pluralize}.side = '#{value}' THEN " +
          "#{klass.name.pluralize}.value ELSE 0.0 END) as #{key}"
    end.join(",")
  end
end
