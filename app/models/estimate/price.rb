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
    validates_presence_of :resource_id, :price_list_id, :rate
    belongs_to :resource, class_name: "::#{::Asset.name}"
    belongs_to :price_list
  end
end
