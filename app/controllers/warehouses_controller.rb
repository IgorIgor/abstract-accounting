# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehousesController < ApplicationController
   def index
     render 'index', layout: false
   end

  def data
    params[:page] ||= 1
    params[:per_page] ||= Settings.root.per_page

    attrs = { page: params[:page], per_page: params[:per_page] }

    if params.has_key?(:like) || params.has_key?(:equal)
      [:like, :equal].each { |type|
        params[type].each { |key, value|
          unless value.empty?
            attrs[:where] ||= {}
            attrs[:where][key] = {}
            attrs[:where][key][type] = value
          end
        } if params[type]
      }
    end

    @warehouses = Warehouse.all(attrs)
    @count = Warehouse.count(attrs)
  end
end
