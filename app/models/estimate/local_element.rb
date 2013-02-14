# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class LocalElement < Base
    validates_presence_of :amount, :price_id
    validates_uniqueness_of :price_id, :scope => :local_id
    belongs_to :price
    belongs_to :local

    def total(field)
      self.price.send(field) * self.amount
    end
  end
end
