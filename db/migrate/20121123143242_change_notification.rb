# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ChangeNotification < ActiveRecord::Migration
  def change
    drop_table :notifications
    create_table :notifications do |t|
      t.integer :notification_type
      t.string :title
      t.text :message
      t.datetime :date
    end
  end
end
