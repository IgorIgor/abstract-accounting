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

    attrs[:without] = params[:without] if params.has_key?(:without)
    if !current_user.root?
      credential = current_user.credentials(:force_update).
          where{document_type == Warehouse.name}.first
      if credential
        attrs[:where] = {} unless attrs.has_key?(:where)
        attrs[:where][:storekeeper_id] = { equal: current_user.entity_id }
        attrs[:where][:storekeeper_place_id] = { equal: credential.place_id }
      end
    end

    attrs[:where] = params[:where] if params[:where]

    @warehouse = Warehouse.all(attrs)
    @count = Warehouse.count(attrs)
  end

  def group
    respond_to do |format|
      format.html { render :group, layout: false }
      format.json do
        params[:page] ||= 1
        params[:per_page] ||= Settings.root.per_page

        attrs = { page: params[:page], per_page: params[:per_page] }

        if params.has_key?(:group_by)
          attrs[:group_by] = params[:group_by]

          @warehouse = Warehouse.group(attrs)
          @count = Warehouse.count(attrs)
          @group_by = params[:group_by]
        end
      end
    end
  end
end
