# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class NotificationsController < ApplicationController
  def new
    @notification = Notification.new
  end

  def create
    params[:notification][:notification_type] = 1
    params[:notification][:date] = DateTime.now
    notification = Notification.create params[:notification]
    notification.assign_users
    render json: { result: 'success', id: notification.id }
  end

  def show
    @notification = Notification.find(params[:id])
  end

  def preview
    render 'notifications/preview', layout: false
  end

  def check
    if current_user.root?
      render :json => { show: false }
    elsif Notification.find_by_user_id(current_user.id).nil?
      render :json => { show: true, html: render_to_string(partial: 'help_view.html') }
    else
      render :json => { show: false }
    end
  end

  def hide
    Notification.create(user_id: current_user.id)
    render :json => { result: "success" }
  end

  def clear
    Notification.destroy_all
    render :json => { result: "success" }
  end
end
