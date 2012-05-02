# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class SqlBuilder
  def self.paginate(attrs)
    limit = ''
    unless attrs.nil? || attrs[:page].nil?
      per_page = attrs[:per_page].nil? ? Settings.root.per_page :
          attrs[:per_page]
      offset = (attrs[:page].to_i - 1) * per_page.to_i
      limit = "LIMIT #{per_page} OFFSET #{offset}"
    end
    limit
  end
end
