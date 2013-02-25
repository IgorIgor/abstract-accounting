# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class SettingsController < ApplicationController
  skip_before_filter :check_chart

  def index
    @money = Chart.first.currency
  end

  def preview
    render 'preview', layout: false
  end

  def new
    @money = Money.new
  end

  def create
    chart = Chart.new
    begin
      Chart.transaction do
        chart.currency = Money.
            find_or_create_by_alpha_code_and_num_code(
              params[:money][:alpha_code],params[:money][:num_code])
        chart.save!
      end
      render json: { result: 'success' }
    rescue
      render json: chart.errors.full_messages
    end
  end
end
