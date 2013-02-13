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
    def index
      render 'index', layout: false
    end

    def preview
      render 'preview', layout: false
    end

    def data
      scope = Local
      scope = scope.search(params[:like]) if params[:like]
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
      params[:local].delete(:catalog)
      if local.update_attributes(params[:local])
        local.items.delete_all
        if params[:items]
          params[:items].values.each do |item|
            if item[:correct] == 'true'
              local.items.create!(price_id: item[:price][:id], amount: item[:amount])
            end
          end
        end
        if local.save!
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
  end
end
