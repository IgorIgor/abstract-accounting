# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class QuoteController < ApplicationController
  def index
    render 'index', layout: false
  end

  def preview
    render 'preview', layout: false
  end

  def new
    @quote = Quote.new
  end

  def show
    @quote = Quote.find(params[:id])
  end

  def data
    filter = generate_paginate
    filter[:sort] = params[:order] if params[:order]
    #TODO: should get filtrate options from client
    @quote = Quote.filtrate(filter)
    @count = Quote.count
  end

  def create
    quote = nil
    begin
      Quote.transaction do
        params[:quote][:day] = DateTime.strptime(params[:quote][:day], "%a %b %d %Y %H:%M:%S")
        quote = Quote.create(params[:quote])
        render json: { result: 'success', id: quote.id }
      end
    rescue
      render json: quote.errors.full_messages
    end
  end

  def update
    quote = Quote.find(params[:id])
    begin
      Quote.transaction do
        params[:quote][:day] = DateTime.parse(params[:quote][:day])
        quote.update_attributes(params[:quote])
        render json: { result: 'success', id: quote.id }
      end
    rescue
      render json: quote.errors.full_messages
    end
  end
end
