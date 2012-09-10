# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module AuthHelpers
  def check_authentication(controller)
    controller.public_instance_methods(false).each do |action|
      it("should redirect from #{action} action to login page") do
        begin
          get action
          response.should redirect_to(login_path)
        rescue ActionController::RoutingError => r
          #do nothing
        else
          get action, :id => 1
          response.should redirect_to(login_path)
        end
      end
    end
  end

  def check_authorization(controller)
    controller.public_instance_methods(false).each do |action|
      it("should have authorization on #{action} action") do
        create(:chart)
        user = create(:user)
        login_user(user)
        begin
          get action
          response.body.should eq("window.location = '/#inbox'")
        rescue ActionController::RoutingError => r
          #do nothing
        else
          get action, :id => 1
          response.body.should eq("window.location = '/#inbox'")
        end
      end
    end
  end

  def check_authorized_load(user_method, actions, &block)
    params = { format: :json }
    params_received = {}
    if actions.has_key?(:params)
      params_received = actions[:params]
      actions.delete(:params)
    end
    actions.each do |name, assignee|
      it("should have authorized load on #{name} action") do
        params = params.merge(params_received[name]) if params_received.has_key?(name)
        user = send(user_method)
        login_user(user)
        get name, params
        assigns(assignee).should match_array(block.call(name, user))
        logout_user
        RootUser.class_eval do
          def sorcery_config
            User.sorcery_config
          end
        end
        user = RootUser.new
        login_user(user)
        get name, params
        assigns(assignee).should match_array(block.call(name, user))
        logout_user
        user = create(:user)
        login_user(user)
        get name, params
        assigns(assignee).should match_array(block.call(name, user))
        logout_user
      end
    end
  end
end

RSpec.configure do |config|
  config.extend(AuthHelpers)
end