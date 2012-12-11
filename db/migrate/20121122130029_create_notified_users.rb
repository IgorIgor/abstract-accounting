# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class CreateNotifiedUsers < ActiveRecord::Migration
  def change
    create_table :notified_users do |t|
      t.integer :user_id
      t.boolean :looked
      t.integer :notification_id
    end
  end
end
