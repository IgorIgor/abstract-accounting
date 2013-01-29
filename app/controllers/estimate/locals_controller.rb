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
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i

      scope = Local
      filter = { paginate: { page: page, per_page: per_page }}
      filter[:sort] = params[:order] if params[:order]

      scope = scope.search(params[:like]) if params[:like]
      @count = scope.count
      @locals = scope.filtrate(filter).order("id ASC")
    end

    def new
      @local = Local.new
    end

    def create
      local = Local.new(params[:local])
      if local.save
        if params[:items]
          params[:items].values.each do |item|
            if item[:correct] == 'true'
              local.items.create(price_list_id: item[:price_list][:id], amount: item[:amount])
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
              local.items.create!(price_list_id: item[:price_list][:id], amount: item[:amount])
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
