# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Comment < ActiveRecord::Base
  validates :user, :item, :message, presence: true

  belongs_to :user
  belongs_to :item, polymorphic: true

  default_scope order("created_at DESC")

  def self.with_item(id, type)
    scoped.where{ (item_id == id) & (item_type == type) }
  end
end
