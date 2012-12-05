# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'
require 'notification'
require 'notified_user'

describe NotificationsController do

  it "should return correct json" do
    user = create(:user)
    login_user(user)
    create :chart
    post :create, notification: attributes_for(:notification)
    JSON.parse(response.body).should eq({'result'=> 'success', 'id'=> 1})
  end

  it "should return correct json" do
    user = create(:user)
    login_user(user)
    create :chart
    title = ''
    251.times { |i| title += i.to_s }
    post :create, notification: attributes_for(:notification, title: title)
    response_body = JSON.parse(response.body)
    response_body.should eq(["#{I18n.t('activerecord.attributes.notification.title') +
      ' ' + I18n.t('errors.messages.too_long.few', count: 250)}"])
  end
end
