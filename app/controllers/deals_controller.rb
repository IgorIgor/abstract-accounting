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

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    @deals = Deal.limit(per_page).offset((page - 1) * per_page).all
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
end
