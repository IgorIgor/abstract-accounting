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

  getter :all do |options = {}|
    build_scopes
    scope = SqlRecord
    scope = scope.paginate(self.paginate_value) if self.paginate_value
    scope.union(@balance_scope.select("id, '#{Balance.name}' as type").to_sql,
                @income_scope.select("id, '#{Income.name}' as type").to_sql).
          all.each do |object|
      self << object.type.constantize.find(object.id, options)
    end
    self
  end

  getter :db_count do
    build_scopes
    SqlRecord.union(@balance_scope.select(:id).to_sql, @income_scope.select(:id).to_sql).count
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

  protected
  def build_scopes
    unless @scopes_updated
      @balance_scope = @balance_scope.in_time_frame(self.date_value + 1, self.date_value)
      @income_scope = @income_scope.in_time_frame(self.date_value + 1, self.date_value)
      @scopes_updated = true
    end
  end

  def retrieve_assets
    build_scopes
    object = SqlRecord.union(@balance_scope.select(build_select_statement(Balance)).to_sql,
                             @income_scope.select(build_select_statement(Income)).to_sql).
                       select("SUM(assets) as assets, SUM(liabilities) as liabilities").first
    @assets = object.assets.to_f
    @liabilities = object.liabilities.to_f
    @assets_retrieved = true
  end

  def build_select_statement(klass)
    {assets: klass::ACTIVE, liabilities: klass::PASSIVE}.map do |key, value|
      "(CASE WHEN side = '#{value}' THEN value ELSE 0.0 END) as #{key}"
    end.join(",")
  end
end
