# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Catalog < Base
    validates :tag, :presence => true
    validates_uniqueness_of :tag, :scope => :parent_id
    belongs_to :parent, class_name: Catalog
    has_many :subcatalogs,  class_name: Catalog, :foreign_key => :parent_id
    has_and_belongs_to_many :boms, class_name: BoM
    has_and_belongs_to_many :price_lists

    def price_list(filter_date, filter_tab)
      # FIXME: it's temporary solution for date comparison
      #  Rplace all datetime to date
      self.price_lists.where{to_char(date, "YYYY-MM-DD").like("#{filter_date.strftime("%Y-%m-%d")}%")}.
                       where{tab.eq(filter_tab)}.first
    end
  end
end
