# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @balances
node(:tag) { |balance| balance.deal.tag }
node(:entity) { |balance| balance.deal.entity.name }
node(:resource) { |balance| balance.deal.give.resource.tag }
node(:debit) do |balance|
  balance.side == Balance::PASSIVE ? balance.value.to_s : nil
end
node(:credit) do |balance|
  balance.side == Balance::ACTIVE ? balance.value.to_s : nil
end
