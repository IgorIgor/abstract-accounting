# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class BoMsController < ApplicationController
  def index
    @boms = BoM.joins(:catalogs).
                where("bo_ms_catalogs.catalog_id = ? AND bo_ms.tab LIKE ?",
                      params[:catalog_id], "#{params[:q]}%").order("bo_ms.tab").limit(5)
  end

  def sum
    params[:date] = Date.parse(params[:date])
    @sum = BoM.find(params[:id]).sum_by_catalog(Catalog.find(params[:catalog_id]),
                                         DateTime.civil(params[:date].year,
                                                        params[:date].month,
                                                        params[:date].mday, 22, 0, 0),
                                         params[:amount].to_f).accounting_norm
  end

  def elements
    params[:date] = Date.parse(params[:date])
    @bom_elements = BoM.find(params[:id]).items
    catalog = Catalog.find(params[:catalog_id])
    @price = catalog.price_list(DateTime.civil(params[:date].year,
                                               params[:date].month,
                                               params[:date].mday,
                                               22, 0, 0),
                                BoM.find(params[:id]).tab)
    @amount = params[:amount].to_f
  end
end
