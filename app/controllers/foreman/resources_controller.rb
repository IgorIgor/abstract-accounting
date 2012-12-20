# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Foreman
  class ResourcesController < ApplicationController
    def index
      render 'index', layout: false
    end

    def data
      @from = (params[:from] && DateTime.parse(params[:from])) ||
          DateTime.current.beginning_of_month
      @to = (params[:to] && DateTime.parse(params[:to])) || DateTime.current
      args = {warehouse_id: 1,
              foreman_id: 30,
              start: @from, stop: @to,
              page: params[:page], per_page: params[:per_page] }
      @resources = WarehouseForemanReport.all(args)
      @count = WarehouseForemanReport.count(args)
    end
  end
end
