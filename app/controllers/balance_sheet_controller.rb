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
    render 'index', layout: "data_with_filter"
  end

  def data
    scope = BalanceSheet
    scope = scope.resource(params[:resource]) if params[:resource]
    scope = scope.entity(params[:entity]) if params[:entity]
    scope = scope.place_id(params[:place_id]) if params[:place_id]
    scope = scope.search(params[:search]) if params[:search]
    scope = scope.order(params[:order]) if params[:order]
    @balances = scope.
        date(params[:date].nil? ? DateTime.now : Date.parse(params[:date])).
        paginate(page: params[:page] || 1, per_page: params[:per_page]).
        all(include: [deal: [:entity, give: [:resource,:place], take: [:resource, :place]]])
  end

  def group
    respond_to do |format|
      format.html { render :group, layout: false }
      format.json do
        scope = BalanceSheet
        scope = scope.resource(params[:resource]) if params[:resource]
        scope = scope.entity(params[:entity]) if params[:entity]
        scope = scope.place_id(params[:place_id]) if params[:place_id]
        scope = scope.date(params[:date].nil? ? DateTime.now : Date.parse(params[:date]))
        @balances_nogroup = scope.clone
        scope = scope.group_by(params[:group_by]) if params[:group_by]
        @balances = scope.
            paginate(page: params[:page] || 1, per_page: params[:per_page]).all
        @group_by = params[:group_by]
      end
    end
  end
end
