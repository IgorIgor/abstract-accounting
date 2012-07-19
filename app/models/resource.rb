# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Resource
  CLASSES = [Asset, Money]

  def initialize(object)
    @object = object.type.constantize.find(object.id)
  end

  def id
    @object.id
  end

  def tag
    if @object.instance_of? Asset
      @object.tag
    elsif @object.instance_of? Money
      @object.alpha_code
    end
  end

  def ext_info
    if @object.instance_of? Asset
      @object.mu
    elsif @object.instance_of? Money
      @object.num_code
    end
  end

  def type
    @object.class.name
  end

  class << self
    def scope
      tables = CLASSES.collect { |item| item.select("id, '#{item.name}' as type").to_sql }
      SqlRecord.union(tables)
    end

    def count
      scope.count
    end

    def all(attrs = {})
      scoped = scope
      if attrs[:page]
        scoped = scoped.paginate(page: attrs[:page], per_page: attrs[:per_page])
      end
      scoped.all.collect { |item| Resource.new(item) }
    end
  end
end
