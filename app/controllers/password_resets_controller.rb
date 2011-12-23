# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class PasswordResetsController < ApplicationController
  skip_before_filter :require_login

  def new
  end

  def create
    user = User.find_by_email(params[:email])
    user.deliver_reset_password_instructions! if user
    redirect_to login_path, :notice => "Instructions have been sent."
  end

  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]
    not_authenticated unless @user
  end

  def update
    @token = params[:token]
    @user = User.load_from_reset_password_token(params[:token])
    not_authenticated unless @user
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.change_password!(params[:user][:password])
      redirect_to login_path, :notice => 'Password was updated.'
    else
      render :action => "edit"
    end
  end

end
