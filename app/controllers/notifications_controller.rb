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
    params[:notification][:date] = DateTime.now
    notification = Notification.new params[:notification]
    Notification.transaction do
      if notification.save
        notification.assign_users
        render json: { result: 'success', id: notification.id }
      else
        render json: notification.errors.full_messages
      end
    end
  end

  def show
    @notification = Notification.find(params[:id])
  end

  def preview
    render 'preview', layout: false
  end

  def index
    render 'index', layout: false
  end

  def data
    notifications = Notification.notifications_for(current_user)
    @notifications = notifications.filtrate(generate_paginate)
    @count = notifications.count
  end

  def check
    if current_user.root?
      render :json => { show: false }
    elsif NotifiedUser.find_by_user_id current_user.id
      notifications = []
      Notification.unviewed_for(current_user).each do |notification|
        notifications << { html: render_to_string(partial: 'notification_view',
                                                  locals: { title: notification.title,
                                                            id: notification.id }),
                           id: notification.id,
                           notification_type: notification.notification_type}
      end
      render :json => { show: true, notifications: notifications }
    else
      render :json => { show: false }
    end
  end

  def hide
    NotifiedUser.find_by_user_id_and_notification_id(current_user.id, params[:id]).
                 update_attribute(:looked, true)
    render :json => { result: "success" }
  end
end
