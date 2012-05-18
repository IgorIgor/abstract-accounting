# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@balances => :objects) do
  node(:tag) { |balance| balance.deal.tag }
  node(:entity) { |balance| balance.deal.entity.name }
  node(:resource) { |balance| balance.deal.give.resource.tag }
  node(:type) { |balance| balance.side == Balance::PASSIVE ? 'debit' : 'credit' }
  node(:amount) { |balance| balance.amount.to_s }
  node(:value) { |balance| balance.value.to_s }
end
node(:total_debit) { @balances.liabilities.to_s }
node(:total_credit) { @balances.assets.to_s }
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @count }
node (:balances_date) { @date }
node (:mu) { @mu }