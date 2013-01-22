# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class RefactorEstimatePriceList < ActiveRecord::Migration
  def change
    drop_table :estimate_prices
    drop_table :estimate_price_lists
    drop_table :estimate_catalogs_price_lists

    create_table :estimate_prices do |t|
      t.date :date
      t.references :bo_m

      t.references :catalog

      t.float :direct_cost
      t.float :workers_cost
      t.float :machinery_cost
      t.float :drivers_cost
      t.float :materials_cost
    end
  end
end
