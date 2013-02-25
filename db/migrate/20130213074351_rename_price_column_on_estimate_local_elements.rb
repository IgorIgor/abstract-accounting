# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class RenamePriceColumnOnEstimateLocalElements < ActiveRecord::Migration
  def change
    rename_column :estimate_local_elements, :price_list_id, :price_id
  end
end
