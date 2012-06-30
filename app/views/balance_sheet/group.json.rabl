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
  node(:group_value) { |balance| balance[:group_column] }
  node(:group_id) { |balance| balance[:group_id] }
  node(:group_type) { |balance| balance[:group_type] }
end
node(:total_debit) { @balances_nogroup.liabilities.to_s }
node(:total_credit) { @balances_nogroup.assets.to_s }
node(:per_page) { params[:per_page] || Settings.root.per_page }
node(:count) { @balances.db_count }
node(:group_by) { @group_by }
