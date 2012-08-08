# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class MoneyController < ApplicationController
  def preview
    render 'money/preview', layout: false
  end

  def new
    @money = Money.new
  end

  def show
    @money = Money.find(params[:id])
  end

  def create
    money = nil
    begin
      Money.transaction do
        money = Money.create(params[:money])
        render json: { result: 'success', id: money.id }
      end
    rescue
      render json: money.errors.full_messages
    end
  end

  def update
    money = Money.find(params[:id])
    begin
      Money.transaction do
        money.update_attributes(params[:money])
        render json: { result: 'success', id: money.id }
      end
    rescue
      render json: money.errors.full_messages
    end
  end
end
