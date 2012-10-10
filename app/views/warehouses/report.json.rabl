# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@warehouse => :objects) do
  attributes :item_id, :side, :amount, :state, :document_id
  node(:date) { |state| state.date.strftime('%Y-%m-%d') }
  glue :entity do
    attributes :name
  end
end
node(:warehouse_id) { params[:warehouse_id] }
child(@warehouses => :warehouses) do
  attributes :place_id, :tag
end
child(@resource ? @resource : Asset.new => :resource) do
  attributes :tag, :mu
end
child(@place ? @place : Place.new => :place) do
  attributes :tag
end
node(:total) { @total }
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
