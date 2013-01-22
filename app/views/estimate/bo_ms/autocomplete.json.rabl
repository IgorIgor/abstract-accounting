# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @boms
attributes :uid
node(:id) { |bom| bom.id }
node(:builders_id) { |bom| bom.builders[0].try(:id)}
node(:builders_rate) { |bom| bom.builders[0].try(:rate) }
node(:rank_id) { |bom| bom.rank[0].try(:id) }
node(:rank_rate) { |bom| bom.rank[0].try(:rate) }
node(:machinist_id) { |bom| bom.machinist[0].try(:id) }
node(:machinist_rate) { |bom| bom.machinist[0].try(:rate) }
node(:machinery) { |bom| Estimate::BoM.filing_items(bom.machinery) }
node(:machinery_length) { |bom| bom.machinery.length }
node(:resources) { |bom| Estimate::BoM.filing_items(bom.resources) }
node(:resources_length) { |bom| bom.resources.length }
node(:tag) { |bom| bom.resource.tag }
node(:mu) { |bom| bom.resource.mu }
