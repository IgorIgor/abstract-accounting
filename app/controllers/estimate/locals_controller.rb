# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class LocalsController < ApplicationController
    layout 'comments'

    def index
      render 'index', layout: false
    end

    def preview
      render 'preview'
    end

    def data
      scope = Local.without_canceled
      scope = scope.search(params[:like]) if params[:like]
      scope = scope.by_project(params[:project_id]) if params[:project_id]
      @count = scope.count

      filter = generate_paginate
      filter[:sort] = params[:order] if params[:order]
      @locals = scope.filtrate(filter).order("id ASC")
    end

    def new
      @local = Local.new(project_id: params[:project_id])
    end

    def create
      local = Local.new(params[:local])
      if local.save
        if params[:items]
          params[:items].values.each do |item|
            if item[:correct] == 'true'
              local.items.create(price_id: item[:price][:id], amount: item[:amount])
            end
          end
        end
        render json: { result: 'success', id: local.id }
      else
        render json: local.errors.full_messages
      end
    end

    def update
      local = Local.find(params[:id])
      params[:local].delete(:boms_catalog)
      if local.update_attributes(params[:local])
        ids = local.items.pluck :id
        if params[:items]
          params[:items].values.each do |item|
            if ids.include? item[:id].to_i
              LocalElement.find(item[:id]).
                  update_attributes(price_id: item[:price][:id], amount: item[:amount])
            elsif item[:id].to_i == 0 and item[:correct] == 'true'
              local.items.build(price_id: item[:price][:id], amount: item[:amount])
            end
            ids.delete item[:id].to_i
          end
          local.items.each { |item| item.delete if ids.include? item.id }
        end
        if local.save
          render json: { result: 'success', id: local.id }
        else
          render json: local.errors.full_messages
        end
      else
        render json: local.errors.full_messages
      end
    end

    def show
      @local = Local.find(params[:id])
    end

    def apply
      local = Local.find(params[:id])
      if local.apply
        render json: { result: 'success', id: local.id }
      else
        render json: local.errors.full_messages
      end
    end

    def cancel
      local = Local.find(params[:id])
      if local.approved
        render json: ["#{I18n.t('views.estimates.locals.canceled_error')}"]
      else
        if local.cancel
          render json: { result: 'success', id: local.id }
        else
          render json: local.errors.full_messages
        end
      end
    end

    def load_local_elements
      if params[:id]
        @local_elements = Local.find(params[:id]).items
        @count = @local_elements.count
      else
        @local_elements = []
        @count = 0
      end
    end
  end
end
