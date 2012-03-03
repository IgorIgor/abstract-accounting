# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @bom_elements
attributes :id, :rate
node(:tag) { |item| item.resource.tag }
node(:cost) { |item| @price.items.where(resource_id: item.resource.id).
                            first.rate.accounting_norm }
node(:sum) { |item| item.sum(@price.items.where(resource_id: item.resource.id).
                            first, @amount).accounting_norm }
