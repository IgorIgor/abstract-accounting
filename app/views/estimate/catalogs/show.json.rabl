# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @catalog.id }
child(@catalog => :catalog) do
  attributes :tag
  node(:parent_tag) { @catalog.parent.nil? ? nil : @catalog.parent.tag }
end
child(@catalog.document => :document) do
  attributes :title, :data
end
node(:have_document) { @have_document }
