# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Document < Base
    has_paper_trail
    attr_accessible :title, :data
    validates_presence_of :title, :data
    validates_uniqueness_of :title
    has_one :catalog
  end
end
