# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Notifiers
  class MailerNotifier
    def update(warning_object)
      user = User.find(warning_object.object.versions.where{item_type == payload.object.class.name &&
          item_id == payload.object.id && event == "create"}.first.whodunnit)
      return true if user.nil?
      recipients = user.managers.inject([user.email]){ |mem, manager| mem<<manager.email }
      NotificationMailer.notification_email(recipients, warning_object).deliver
    end
  end
end
