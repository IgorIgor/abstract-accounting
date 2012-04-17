# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class HomeController < ApplicationController
  def index
  end

  def inbox
    render "home/documents", :layout => false
  end

  def inbox_data
    types = [ Waybill.name, Distribution.name ]

    @versions = VersionEx.lasts.by_type(types).
      paginate(page: params[:page], per_page: params[:per_page]).
      all(include: [item: [:versions, :storekeeper]])
    @count = VersionEx.lasts.by_type(types).count
  end
end
