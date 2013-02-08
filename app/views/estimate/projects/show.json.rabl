# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @project.id }
node(:type) { @project.class.name }
child(@project => :project) do
  attributes :place_id, :customer_id, :customer_type
  child(:place => :place) do
    attributes :tag
  end
  if @project.customer_type == LegalEntity.name
    child(:customer => :legal_entity) do
      attributes :tag, :identifier_value
    end
    child(Entity.new => :entity) do
      attributes :tag
    end
  else
    child(LegalEntity.new => :legal_entity) do
      attributes :tag, :identifier_value
    end
    child(:customer => :entity) do
      attributes :tag
    end
  end
end
