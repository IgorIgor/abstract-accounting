# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale, :require_login, :check_chart

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  alias_method :sorcery_auto_login, :auto_login
  def auto_login(user)
    (((session[:root] = true) && (@current_user = user)) if user.root?) || sorcery_auto_login(user)
  end

  alias_method :sorcery_remember_me!, :remember_me!
  def remember_me!
    sorcery_remember_me! unless current_user.root?
  end

  alias_method :sorcery_forget_me!, :forget_me!
  def forget_me!
    sorcery_forget_me! unless current_user.root?
  end

  def autorize_warehouse(klass, options = {})
    options = {
        alias: klass
    }.merge(options)
    if current_user.root?
      klass
    else
      credential = current_user.credentials(:force_update).
          where{document_type == options[:alias].name}.first
      if credential
        klass.by_warehouse(credential.place)
      else
        nil
      end
    end
  end

  protected
  alias_method :sorcery_login_from_session, :login_from_session
  def login_from_session
    @current_user = (RootUser.new if session[:root]) || sorcery_login_from_session
  end

  private
  def not_authenticated
    redirect_to login_path, alert: t('alert.unauthorized_access')
  end

  def check_chart
    render :js => "window.location = '/#settings/new'" unless Chart.count > 0
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :js => "window.location = '/#inbox'"
  end
end
