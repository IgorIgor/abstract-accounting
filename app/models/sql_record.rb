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
    @page = 1
    @per_page = Settings.root.per_page
    unless params.nil? || params[:page].nil?
      @per_page = params[:per_page].to_i if params[:per_page]
      @page = params[:page].to_i
    end
    self
  end

  def initialize()
    @sql = ""
  end

  def to_sql
    @sql
  end

  def select(str)
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    limit = ''
    if @page && @per_page
      limit = "LIMIT #{@per_page} OFFSET #{(@page - 1) * @per_page}"
    end
    execute("SELECT #{str} FROM (#{@sql}) #{limit}")
  end

  def all
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    select("*")
  end

  def count
    raise Exception.new("Could not select from empty sql") if @sql.empty?
    items = ActiveRecord::Base.connection.execute("SELECT count(*) as cnt FROM (#{@sql})")
    return 0 if items.empty?
    items.first["cnt"].to_i
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
  end
end
