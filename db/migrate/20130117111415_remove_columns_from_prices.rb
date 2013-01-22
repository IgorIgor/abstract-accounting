# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class RemoveColumnsFromPrices < ActiveRecord::Migration
  def change
    remove_column :estimate_prices, :resource_id
    remove_column :estimate_price_lists, :resource_id
    remove_column :estimate_price_lists, :tab
    drop_table :estimate_catalogs_price_lists
  end
end
