# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class CatalogsController < ApplicationController
  def index
    if params[:id]
      catalog = Catalog.find(params[:id])
      @catalogs = catalog.parent ? catalog.parent.subcatalogs : Catalog.where(:parent_id => nil)
    else
      @catalogs = Catalog.where(:parent_id => params[:parent_id])
    end
  end
end
