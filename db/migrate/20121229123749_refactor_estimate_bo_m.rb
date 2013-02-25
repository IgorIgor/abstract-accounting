# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class RefactorEstimateBoM < ActiveRecord::Migration
  def change
    drop_table :estimate_bo_m_elements
    drop_table :estimate_bo_ms_catalogs

    rename_column :estimate_bo_ms, :tab, :uid

    add_column :estimate_bo_ms, :catalog_id, :integer
    add_column :estimate_bo_ms, :parent_id, :integer

    add_column :estimate_bo_ms, :amount, :float
    add_column :estimate_bo_ms, :workers_amount, :float
    add_column :estimate_bo_ms, :avg_work_level, :float
    add_column :estimate_bo_ms, :drivers_amount, :float

    add_column :estimate_bo_ms, :bom_type, :integer

    add_index :estimate_bo_ms, :uid
  end
end
