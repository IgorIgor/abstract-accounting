# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@legal_entity => :legal_entity) do
  attributes :name, :country_id, :identifier_name, :identifier_value
end
child(Country.new => :country) do
  attributes :tag
end
