# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class AddIndicesToRules < ActiveRecord::Migration
  def change
    add_index :rules, :deal_id
    add_index :rules, :to_id
    add_index :rules, :from_id
  end
end
