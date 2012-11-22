# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Notification < ActiveRecord::Base
  attr_accessible :date, :message, :title, :notification_type
  has_many :notified_users

  def assign_users
    User.pluck(:id).each do |user_id|
      self.notified_users.create(user_id: user_id, looked: false)
    end
  end
end
