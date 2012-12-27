# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class PriceList < ActiveRecord::Base
    has_paper_trail

    validates_presence_of :resource_id, :date, :tab
    belongs_to :resource, class_name: "::#{Asset.name}"
    has_many :items, class_name: Price
    has_and_belongs_to_many :catalogs
  end
end
