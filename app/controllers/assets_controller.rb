# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class AssetsController < ApplicationController
  def index
    @assets = Asset
    if params[:term]
      @assets = Asset.where{lower(tag).like lower("%#{my{params[:term]}}%")}.
          order("tag").limit(5)
    end
    filter = {}
    filter = {search: params[:like]} if params[:like]
    @count = Asset.filtrate(filter).count
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter[:paginate] = { page: page, per_page: per_page }
    @assets = Asset.filtrate(filter)
  end

  def preview
    render 'assets/preview', layout: false
  end

  def new
    @asset = Asset.new
  end

  def show
    @asset = Asset.find(params[:id])
  end

  def create
    asset = nil
    begin
      Asset.transaction do
        asset = Asset.create(params[:asset])
        render json: { result: 'success', id: asset.id }
      end
    rescue
      render json: asset.errors.full_messages
    end
  end

  def update
    asset = Asset.find(params[:id])
    begin
      Asset.transaction do
        asset.update_attributes(params[:asset])
        render json: { result: 'success', id: asset.id }
      end
    rescue
      render json: asset.errors.full_messages
    end
  end
end
