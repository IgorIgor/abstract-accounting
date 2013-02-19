# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @local.id }
node(:type) { @local.class.name }
child(@local => :local) do
  attributes :tag, :date
  node(:approved) { |l| l.approved.strftime('%Y-%m-%d') if l.approved }
  node(:canceled) { |l| l.canceled.strftime('%Y-%m-%d') if l.canceled }
end
child(@local.boms_catalog => :boms_catalog) { attributes :id }
child(@local.prices_catalog => :prices_catalog) { attributes :id }
child([] => :items)
