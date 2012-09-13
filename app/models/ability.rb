# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :index, :preview, :show, :data, :list, :group, :resources, to: :group_read
    if user && user.root?
      can :manage, :all
    elsif user
      manage_by_credentials(user, :manage)
      user.managed_group.users.each do |u|
        manage_by_credentials(u, :group_read)
      end if user.managed_group(:force_update)
    end
  end

  def manage_by_credentials(user, action)
    user.credentials(:force_update).each do |c|
      can action, c.document_type.constantize
    end
  end
end
