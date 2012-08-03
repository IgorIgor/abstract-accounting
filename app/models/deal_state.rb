# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DealState < ActiveRecord::Base
  attr_accessible :close, :open
  belongs_to :deal

  validates_uniqueness_of :deal_id
  validates_presence_of :open

  def in_work?
    self.close.nil?
  end

  def closed?
    !self.in_work?
  end
end
