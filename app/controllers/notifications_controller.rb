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
    begin
      params[:notification][:date] = DateTime.now
      notification = Notification.create params[:notification]
      notification.assign_users
      render json: { result: 'success', id: notification.id }
    rescue
      render json: notification.errors.full_messages
    end
  end

  def show
    @notification = Notification.find(params[:id])
  end

  def preview
    render 'notifications/preview', layout: false
  end

  def index
    render 'index', layout: false
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter = { paginate: { page: page, per_page: per_page }}
    notifications = Notification.notifications_for(current_user)
    @notifications = notifications.filtrate(filter)
    @count = notifications.count
  end

  def check
    if current_user.root?
      render :json => { show: false }
    elsif NotifiedUser.find_by_user_id current_user.id
      notifications = []
      Notification.unviewed_for(current_user).each do |notification|
        notifications << { html: render_to_string(partial: 'notification_view.html',
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
