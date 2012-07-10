# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@resources => :objects) do
  node(:id) { |item| item.resource.id }
  node(:tag) { |item| item.resource.tag }
  node(:mu) { |item| item.resource.mu }
  node(:amount) { |item| item.amount }
  node(:price) { |item| item.price }
  node(:sum) { |item| item.price * item.amount }
  node(:exp_amount) { |item| item.exp_amount }
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
