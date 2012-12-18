# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Term < ActiveRecord::Base
  has_paper_trail

  validates :deal_id, :resource_id, :presence => true
  validates_uniqueness_of :deal_id, :scope => [:side]
  belongs_to :deal
  belongs_to :place
  belongs_to :type, :class_name => Classifier
  belongs_to :resource, :polymorphic => true

  sifter :by_resource do |warehouse_id|
    place_id == warehouse_id
  end
end
