# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class PricesController < ApplicationController
    def index
      if params[:bom_id]
        @prices = Estimate::Price.with_bo_m_id(params[:bom_id])
      else
        render 'index', layout: false
      end
    end

    def data
      scope = Price
      scope = scope.with_catalog_id(params[:catalog_id]) if params[:catalog_id]
      @count = scope.count

      filter = generate_paginate
      filter[:sort] = params[:order] if params[:order]
      @prices = scope.filtrate(filter).all
    end

    def find
      data = nil
      if params[:bom_id] && params[:date]
        data = Estimate::Price.
            with_bo_m_id(params[:bom_id]).
            with_date_less_or_eq_to(params[:date])
      end
      if params[:bom_uid] && params[:date] && params[:catalog_id]
        data = Estimate::Price.
            with_date_less_or_eq_to(params[:date]).
            with_uid(params[:bom_uid]).
            with_catalog_pid(params[:catalog_id])
      end
      data = data.order{date.desc}.first if !!data
      if data
        @price = data
        @bom = @price.bo_m
      else
        @price = @bom = nil
      end
    end

    def preview
      render 'preview', layout: false
    end

    def new
      @price = Price.new
    end

    def show
      @price = Price.find params[:id]
    end

    def create
      Price.transaction do
        price = Price.new(price_params)
        if price.save
          render json: { result: 'success', id: price.id }
        else
          render json: price.errors.full_messages
        end
      end
    end

    def update
      price = Price.find params[:id]
      Price.transaction do
        if price.update_attributes(price_params)
          render json: { result: 'success', id: price.id }
        else
          render json: price.errors.full_messages
        end
      end
    end

    private
      def price_params
        params[:price][:date] = DateTime.parse(params[:price][:date]).
            change(hour: 12, offset: 0)
        params[:price].delete(:uid)
        params[:price].delete(:tag)
        params[:price].delete(:mu)
        params[:price]
      end
  end
end
