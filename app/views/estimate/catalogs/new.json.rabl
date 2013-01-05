# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@catalog => :catalog) do
  attributes :tag
  node(:parent_id) {@parent.nil? ? nil : @parent.id}
  node(:parent_tag) {@parent.nil? ? nil : @parent.tag}
end
child(Estimate::Document.new => :document) do
  attributes :tag, :data
end
node(:have_document) { false }
