# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Group < ActiveRecord::Base
  has_paper_trail
  validates_presence_of :manager_id, :tag
  validates_uniqueness_of :tag
  belongs_to :manager, :class_name => 'User'
  has_and_belongs_to_many :users
end
