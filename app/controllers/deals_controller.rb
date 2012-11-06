# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DealsController < ApplicationController
  def index
    if params[:term]
      term = params[:term]
      @deals = Deal.where{tag.like "%#{term}%"}.order('tag').limit(5)
    else
      render 'index', layout: false
    end
  end

  def preview
    render 'deals/preview', layout: false
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter = { paginate: { page: page, per_page: per_page }}
    filter[:sort] = params[:order] if params[:order]
    #TODO: should get filtrate options from client
    @deals = Deal.filtrate(filter)
    @count = Deal.count
  end

  def rules
    deal = Deal.find(params[:id])

    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i

    @rules = deal.rules.limit(per_page).offset((page - 1) * per_page).all
    @count = deal.rules.count
  end

  def new
    @deal = Deal.new
  end

  def show
    @deal = Deal.find(params[:id])
  end

  def create
    deal = nil
    unless params[:deal][:execution_date].nil?
      params[:deal][:execution_date] = DateTime.parse(params[:deal][:execution_date]).change(hour: 12, offset: 0)
    end
    begin
      Deal.transaction do
        deal = Deal.new(params[:deal])
        deal.build_give(resource_id: params[:give][:resource_id],
                        resource_type: params[:give][:resource_type],
                        place_id: params[:give][:place_id])
        deal.build_take(resource_id: params[:take][:resource_id],
                        resource_type: params[:take][:resource_type],
                        place_id: params[:take][:place_id])
        deal.save!
        params[:rules].values.each { |item| deal.rules.create!(fact_side: item[:fact_side],
                                                               change_side: item[:change_side],
                                                               rate: item[:rate],
                                                               from_id: item[:from_id],
                                                               to_id: item[:to_id]) }
        render json: { result: 'success', id: deal.id }
      end
    rescue
      render json: deal.errors.full_messages
    end
  end

  def update
    deal = Deal.find(params[:id])
    if params[:deal][:execution_date].nil?
      params[:deal][:execution_date] = nil
      params[:deal][:compensation_period] = nil
    else
      params[:deal][:execution_date] = DateTime.parse(params[:deal][:execution_date]).change(hour: 12, offset: 0)
    end
    begin
      Deal.transaction do
        deal.update_attributes(params[:deal])
        deal.give.update_attributes(resource_id: params[:give][:resource_id],
                                    resource_type: params[:give][:resource_type],
                                    place_id: params[:give][:place_id])
        deal.take.update_attributes(resource_id: params[:take][:resource_id],
                                    resource_type: params[:take][:resource_type],
                                    place_id: params[:take][:place_id])
        deal.rules.delete_all
        params[:rules].values.each { |item| deal.rules.create!(fact_side: item[:fact_side],
                                                               change_side: item[:change_side],
                                                               rate: item[:rate],
                                                               from_id: item[:from_id],
                                                               to_id: item[:to_id]) }
        render json: { result: 'success', id: deal.id }
      end
    rescue
      render json: deal.errors.full_messages
    end
  end
end
