# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class SqlRecord
  class << self
    def builder(name, &block)
      define_method name, &block
      define_singleton_method name do |*args|
        self.new.send(name, *args)
      end
    end
  end

  builder :union do |*args|
    @sql = args.join(" UNION ")
    self
  end

  builder :paginate do |params = {}|
    page = 1
    per_page = Settings.root.per_page
    unless params.nil? || params[:page].nil?
      per_page = params[:per_page].to_i if params[:per_page]
      page = params[:page].to_i
    end
    limit(per_page).offset((page - 1) * per_page)
    self
  end

  builder :from do |sql|
    @sql = sql
    self
  end
  builder :join do |join|
    @joins += " #{join}"
    self
  end

  builder :where do |attrs = {}|
    condition = attrs.inject([]) do |cond, (key, value)|
      cond << "T.#{key} LIKE '%#{value[:like]}%'" if value[:like]
    end.join(' AND ')
    @where =  "WHERE #{condition}"
    self
  end

  builder :limit do |value|
    @limit = "LIMIT #{value}"
    self
  end

  builder :order_by do |value|
    @order_by = "ORDER BY #{value}"
    self
  end

  builder :order do |value|
    @order_by = "ORDER BY #{value}"
    self
  end

  builder :offset do |value|
    @offset = "OFFSET #{value}"
    self
  end

  def initialize()
    @sql = ""
    @joins = ""
  end

  def to_sql
    @sql
  end

  def select(str)
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    execute("SELECT #{str} FROM (#{@sql}) T #{@joins} #{@where} #{@order_by} #{@limit} #{@offset}")
  end

  def all
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    select("*")
  end

  def count
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    items = ActiveRecord::Base.connection.execute("SELECT count(T.*) as cnt FROM (#{@sql}) T")
    return 0 if items.count == 0
    Converter.int(items.first["cnt"])
  end

  private
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql).collect do |item|
      SqlRecordObject.new(item.inject({}) do |memo, (k,v)|
        memo[k.split(".").last.gsub(/^"(.*?)"$/,'\1')] = v if k.instance_of?(String)
        memo
      end)
    end
  end

  class SqlRecordObject < Object
    def initialize(record)
      @record = record
    end

    def id
      Converter.int(self["id"])
    end

    def method_missing(meth, *args, &block)
      if @record.has_key?(meth.to_s)
        @record[meth.to_s]
      else
        super
      end
    end

    def respond_to?(meth)
      if @record.has_key?(meth.to_s)
        true
      else
        super
      end
    end

    def [](key)
      @record[key.to_s]
    end
  end
end
