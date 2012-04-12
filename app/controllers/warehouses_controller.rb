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
    attrs = {}
    if params.has_key?(:filter)
      params[:filter].each { |key, value|
        unless value.empty?
          attrs[:where] ||= {}
          attrs[:where][key] = { like: value }
        end
      }
    end

    @data = Warehouse.all(attrs)
  end
end
