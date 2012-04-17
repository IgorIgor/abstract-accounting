# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class VersionEx < Version
  scope :lasts, joins('INNER JOIN
                        (SELECT item_id, MAX(created_at) as last_create
                        FROM versions GROUP BY item_id, item_type) grouped
                      ON versions.item_id = grouped.item_id AND
                      versions.created_at = grouped.last_create')

  def self.by_type types
    where(types.map{|item| "item_type='#{item}'"}.join(' OR '))
  end

  def self.paginate(attrs = {})
    page = 1
    per_page = Settings.root.per_page
    unless attrs.nil?
      unless attrs[:page].nil?
        page = attrs[:page].to_i
      end
      unless attrs[:per_page].nil?
        per_page = attrs[:per_page].to_i
      end
    end

    limit(per_page).offset((page - 1) * per_page)
  end
end
