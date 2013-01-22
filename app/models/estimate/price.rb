# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Price < Base
    validates_presence_of :date, :bo_m_id, :direct_cost
    validates_uniqueness_of :date, :scope => [:bo_m_id, :catalog_id]

    belongs_to :bo_m, class_name: BoM
    belongs_to :catalog

    delegate :uid, :tag, :mu, to: :bo_m, allow_nil: true
  end
end
