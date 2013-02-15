# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@locals => :objects) do
  attributes :id, :tag
  glue :class do
    attributes :name => :type
  end
  node(:date) { |local| local.date.strftime('%Y-%m-%d') }
  node(:comments_count) { |local| local.comments.count }
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
