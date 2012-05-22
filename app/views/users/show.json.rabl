# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@user => :user) do
  attributes :id, :email, :entity_id
  node(:password) { "" }
  node(:password_confirmation) { "" }
end
child(@user.entity => :entity) do
  attributes :tag
end
child(@user.credentials(:force_update) => :credentials) do
  attributes :document_type
  glue(:place) { attributes :tag }
end