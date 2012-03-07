# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Waybill < ActiveRecord::Base
  has_paper_trail

  validates :document_id, :legal_entity_id, :place_id, :entity_id,
            :created, :presence => true
  validates_uniqueness_of :document_id
  belongs_to :legal_entity
  belongs_to :place
  belongs_to :entity
end
