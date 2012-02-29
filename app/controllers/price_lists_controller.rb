# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class PriceListsController < ApplicationController
  def index
    @price_lists = PriceList.joins(:catalogs).
        where("catalogs_price_lists.catalog_id = ?", params[:catalog_id]).
        select(:date).uniq.where("date LIKE ?", "#{params[:q]}%").order("date").limit(5)
  end
end
