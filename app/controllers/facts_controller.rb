# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class FactsController < ApplicationController
  def preview
    render 'facts/preview', layout: false
  end

  def new
    @fact = Fact.new
  end

  def show
    @fact = Fact.find(params[:id])
  end

  def create
    params[:fact][:day] = DateTime.parse(params[:fact][:day]).change(hour: 12, offset: 0)
    from_deal = Deal.find(params[:fact][:from_deal_id])
    params[:fact][:resource_id] = from_deal.take.resource_id
    params[:fact][:resource_type] = from_deal.take.resource_type
    fact = Fact.new(params[:fact])
    if fact.save
      render json: { result: 'success', id: fact.id }
    else
      render json: fact.errors.full_messages
    end
  end
end
