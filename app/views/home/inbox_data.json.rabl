# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @data
attributes :id
node(:type) { |item| item.class.name.pluralize.downcase }
node(:name) { |item| item.class.name }
node(:sum) { 0.0 }
node(:content) { |item| item.storekeeper.tag }
node(:created_at) { |item| item.versions.first.created_at.strftime('%Y-%m-%d') }
node(:update_at) { |item| item.versions.last.created_at.strftime('%Y-%m-%d') }
