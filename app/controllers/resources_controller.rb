# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ResourcesController < ApplicationController
  def index
    if params[:term]
      @resources = Resource.where({tag: {like: params[:term]}}).limit(5).order_by('tag').all
    else
      render 'index', layout: false
    end
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    @resources = Resource.all(page: page, per_page: per_page)
    @count = Resource.count
  end
end
