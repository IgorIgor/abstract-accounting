# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@allocations => :objects) do
  attributes :id
  node(:created) { |allocation| allocation.created.strftime('%Y-%m-%d') }
  node(:storekeeper) { |allocation| allocation.storekeeper.tag }
  node(:storekeeper_place) { |allocation| allocation.storekeeper_place.tag }
  node(:foreman) { |allocation| allocation.foreman.tag }
  node(:state) do |allocation|
    case allocation.state
    when Statable::UNKNOWN
      I18n.t 'views.statable.unknown'
    when Statable::INWORK
      I18n.t 'views.statable.inwork'
    when Statable::CANCELED
      I18n.t 'views.statable.canceled'
    when Statable::APPLIED
      I18n.t 'views.statable.applied'
    end
  end
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
