# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@versions => :objects) do
  node(:id) { |version| version.item.id }
  node(:type) { |version| version.item.class.name.pluralize.downcase }
  node(:name) { |version| version.item.class.name }
  node(:sum) { 0.0 }
  node(:content) { |version| version.item.storekeeper.tag }
  node(:created_at) { |version| version.item.versions.first.created_at.strftime('%Y-%m-%d') }
  node(:update_at) { |version| version.item.versions.last.created_at.strftime('%Y-%m-%d') }
end
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @count }
