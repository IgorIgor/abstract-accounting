# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

#collection @resources
#glue :resource do
#  attributes :id, :tag, :mu
#end
#attributes :amount, :exp_amount

object false
child(@resources => :objects) do
  node(:id) { |item| item.resource.id }
  node(:tag) { |item| item.resource.tag }
  node(:mu) { |item| item.resource.mu }
  node(:amount) { |item| item.amount }
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
