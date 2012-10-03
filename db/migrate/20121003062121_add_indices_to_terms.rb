# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class AddIndicesToTerms < ActiveRecord::Migration
  def change
    add_index :terms, [:deal_id, :side], unique: true
    add_index :terms, :place_id
    add_index :terms, :resource_id
    add_index :terms, :resource_type
    add_index :terms, :type_id
  end
end
