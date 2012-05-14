# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class BalanceSheetController < ActionController::Base
  def index
    render 'index', layout: false
  end

  def data
    @date = params[:date].nil? ? nil : Date.parse(params[:date])
    @balances = BalanceSheet.all(date: @date,
                                 include: [deal: [:entity, give: [:resource]]],
                                 page: params[:page] || 1,
                                 per_page: params[:per_page])
    @count = BalanceSheet.count(@date || DateTime.now)
  end
end
