# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class UsersController < ApplicationController
  def preview
    render "users/preview", :layout => false
  end

  def new
    @user = User.new
  end

  def create
    user = nil
    begin
      User.transaction do
        user = User.new(params[:user])
        unless user.entity
          user.entity = Entity.create!(tag: params[:entity][:tag])
        end
        user.save!
      end
      render :text => "success"
    rescue
      render json: user.errors.messages
    end
  end
 end
