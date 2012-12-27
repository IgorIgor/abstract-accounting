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
    authorize_resource class: WarehouseForemanReport.name
    def index
      render 'index', layout: false
    end

    def data
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i
      @from = (params[:from] && DateTime.parse(params[:from])) ||
          DateTime.current.beginning_of_month
      @to = (params[:to] && DateTime.parse(params[:to])) || DateTime.current
      if current_user.root?
        @resources = []
        @count = 0
      else
        credential = current_user.credentials.with_document_type(WarehouseForemanReport.name)
        args = {warehouse_id: credential[0][:place_id],
                foreman_id: current_user.entity_id,
                start: @from, stop: @to }
        unless params[:format] == 'pdf' or params[:format] == 'html'
          args[:page] = page
          args[:per_page] = per_page
        end
        @resources = WarehouseForemanReport.all(args)
        @count = WarehouseForemanReport.count(args)
      end
      respond_to do |format|
        format.json { render :data }
        format.html { render :print, layout: false }
        format.pdf do
          render pdf: 'foreman/resources/print.pdf',
                 :template => 'foreman/resources/print.erb',
                 :formats => [:html],
                 encoding: 'utf-8',
                 layout: false
        end
      end
    end
  end
end
