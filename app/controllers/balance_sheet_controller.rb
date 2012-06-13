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
    scope = BalanceSheet
    scope = scope.resource_id(params[:resource_id]) if params[:resource_id]
    @balances = scope.
        date(params[:date].nil? ? DateTime.now : Date.parse(params[:date])).
        paginate(page: params[:page] || 1, per_page: params[:per_page]).
        all(include: [deal: [:entity, give: [:resource]]])
  end
end
