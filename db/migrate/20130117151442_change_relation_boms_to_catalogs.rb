# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ChangeRelationBomsToCatalogs < ActiveRecord::Migration
  def change
    drop_table :estimate_bo_ms_catalogs
    add_column :estimate_bo_ms, :catalog_id, :integer
  end
end
