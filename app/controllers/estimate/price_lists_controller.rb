# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class PriceListsController < ApplicationController
    def index
      @price_lists = PriceList.joins(:catalogs).
          where("catalogs_price_lists.catalog_id = ?", params[:catalog_id]).
          select(:date).uniq.where("date LIKE ?", "#{params[:q]}%").order("date").limit(5)
    end

    def preview
      render 'estimate/price_lists/preview', layout: false
    end

    def new
      @price_list = PriceList.new
    end

    def show
      @price_list = PriceList.find params[:id]
    end

    def create
      if params[:resource]
        PriceList.transaction do
          price_list = PriceList.new(bo_m_id: params[:price_list][:bo_m_id],
                                     date: DateTime.parse(params[:price_list][:date]).
                                                    change(hour: 12, offset: 0))
          price_list.build_items params[:elements]
          if price_list.save
            render json: { result: 'success', id: price_list.id }
          else
            render json: price_list.errors.full_messages
          end
        end
      else
        render json: ["#{I18n.t('views.estimates.uid')} : #{I18n.t('errors.messages.invalid')}"]
      end
    end

    def update
      if params[:resource]
        price_list = PriceList.find params[:id]
        PriceList.transaction do
          price_list.items.delete_all
          price_list.build_items params[:elements]
          if price_list.update_attributes(bo_m_id: params[:price_list][:bo_m_id],
                                          date: DateTime.parse(params[:price_list][:date]).
                                              change(hour: 12, offset: 0))
            render json: { result: 'success', id: price_list.id }
          else
            render json: price_list.errors.full_messages
          end
        end
      else
        render json: ["#{I18n.t('views.estimates.uid')} : #{I18n.t('errors.messages.invalid')}"]
      end
    end
  end
end
