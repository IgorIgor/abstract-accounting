# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@group => :group) do
  attributes :id, :tag, :manager_id
end
child(@group.manager => :manager) do
  glue :entity do
    attributes :tag
  end
end
child(@group.users => :users) do
  attributes :id
  glue :entity do
    attributes :tag
  end
end
