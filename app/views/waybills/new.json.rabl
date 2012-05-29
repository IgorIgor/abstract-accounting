# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@waybill => :waybill) do
  attributes :created, :document_id, :state,
             :distributor_id, :distributor_place_id,
             :storekeeper_id, :storekeeper_place_id
end
child(LegalEntity.new => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(@waybill.build_distributor_place => :distributor_place) { attributes :tag }
child((@waybill.storekeeper ? @waybill.storekeeper : Entity.new) => :storekeeper) do
  attributes :tag
end
place = @waybill.storekeeper_place
unless place
  place = @waybill.build_storekeeper_place
end
child(place => :storekeeper_place) { attributes :tag }
child([] => :items)
