# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GeneralLedgerController < ApplicationController
  def index
    render 'index', layout: false
  end

  def data
    @date = params[:date]
    scope = GeneralLedger.on_date(@date)
    scope = scope.by_deal(params[:deal_id]) if params[:deal_id]
    scope = scope.by_deals(params[:deal_ids]) if params[:deal_ids]

    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter = { paginate: { page: page, per_page: per_page }}
    filter[:sort] = params[:order] if params[:order]
    #TODO: should get filtrate options from client
    @gl = scope.filtrate(filter).all(include: [fact: [:resource, :to, :from]])
    @count = scope.count
  end
end
