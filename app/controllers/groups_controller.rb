# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GroupsController < ApplicationController
  def preview
    render 'groups/preview', layout: false
  end

  def new
    @group = Group.new
  end

  def create
    group = nil
    begin
      Group.transaction do
        group = Group.create(params[:group])
        group.user_ids = params[:users].values.map{ |item| item[:id] }
        render text: 'success'
      end
    rescue
      render json: group.errors.messages
    end
  end
end
