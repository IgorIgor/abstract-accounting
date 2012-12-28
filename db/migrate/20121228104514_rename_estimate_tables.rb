# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class RenameEstimateTables < ActiveRecord::Migration
  def change
    rename_column :estimate_elements, :estimate_id, :local_id

    rename_table :estimates, :estimate_locals
    rename_table :estimate_elements, :estimate_local_elements
    rename_table :bo_ms, :estimate_bo_ms
    rename_table :bo_ms_catalogs, :estimate_bo_ms_catalogs
    rename_table :bo_m_elements, :estimate_bo_m_elements
    rename_table :catalogs, :estimate_catalogs
    rename_table :catalogs_price_lists, :estimate_catalogs_price_lists
    rename_table :prices, :estimate_prices
    rename_table :price_lists, :estimate_price_lists
  end
end
