# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class CombinedRelation

  def initialize(sql_record)
    @scope = sql_record
  end

  def where(attrs)
    @scope = @scope.where(attrs)
    self
  end

  def limit(value)
    @scope = @scope.limit(value)
    self
  end

  def order_by(value)
    @scope = @scope.order_by(value)
    self
  end

  def paginate(attrs)
    @scope = @scope.paginate(attrs)
    self
  end

  def count
    @scope.count
  end

  def all
    @scope.all
  end
end
