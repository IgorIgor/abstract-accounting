# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @estimates
attributes :id
node(:type) { "Estimate" }
node(:sum) { |item| item.items.reduce(0) { |sum, elem| sum + elem.bom.sum_by_catalog(item.catalog, item.date, elem.amount) } }
node(:content) { |item| item.legal_entity.name }
node(:created_at) { |item| item.versions.first.created_at.strftime("%Y-%m-%d") }
node(:update_at) { |item| item.versions.last.created_at.strftime("%Y-%m-%d") }
