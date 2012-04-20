# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

collection @gl

node(:day) { |txn| txn.fact.day.strftime('%Y-%m-%d') }
node(:amount) { |txn| txn.fact.amount.to_s }
node(:resource) { |txn| txn.fact.resource.tag }
node(:type_debit) do |txn|
  txn.fact.to.nil? ? nil : I18n.t('views.general_ledger.debit')
end
node(:account_debit) { |txn| txn.fact.to.nil? ? nil : 'some account' }
node(:price_debit) { |txn| txn.fact.to.nil? ? nil : txn.value.to_s }
node(:debit_debit) { |txn| txn.fact.to.nil? ? nil : txn.earnings.to_s }
node(:type_credit) do |txn|
  txn.fact.from.nil? ? nil : I18n.t('views.general_ledger.credit')
end
node(:account_credit) { |txn| txn.fact.from.nil? ? nil : 'some account' }
node(:price_credit) { |txn| txn.fact.from.nil? ? nil : txn.value.to_s }
node(:credit_credit) { |txn| txn.fact.from.nil? ? nil : txn.earnings.to_s }
