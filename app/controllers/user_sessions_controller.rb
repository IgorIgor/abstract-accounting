# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class UserSessionsController < ApplicationController
  skip_before_filter :require_login, except: [:destroy]
  skip_before_filter :check_chart

  layout 'login'

  def new
  end

  def create
    user = login(params[:email], params[:password], params[:remember_me])
    if user
      redirect_to root_path
    else
      redirect_to login_path, alert: t('views.user_sessions.notice.invalid_data')
    end
  end

  def destroy
    logout
    redirect_to login_path
  end
end
