# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Notifiers
  class UINotifier
    def update(warning_object)
      version = warning_object.object.versions.where{item_type == payload.object.class.name &&
          item_id == payload.object.id && event == "create"}.first
      return unless version && version.whodunnit.to_i != 0
      user = User.find(version.whodunnit)
      return true if user.nil?
      recipients = user.managers.inject([user.id]){ |mem, manager| mem<<manager.id }
      notification = self.send(warning_object.class.name.demodulize.underscore, warning_object, user)
      recipients.each do |user_id|
        notification.notified_users.create(user_id: user_id, looked: false)
      end
    end

    def deal_priority(warning_object, user)
      Notification.create(title: I18n.t('warnings.deal.priority.title', user: user.entity.tag),
                          message: I18n.t('warnings.deal.priority.message',
                                          warning_object_id: warning_object.object.id,
                                          warning_object_tag: warning_object.object.tag,
                                          expected_id: warning_object.expected.id,
                                          expected_tag: warning_object.expected.tag,
                                          got_id: warning_object.got.id,
                                          got_tag: warning_object.got.tag),
                          notification_type: Notification::WARNING,
                          date: DateTime.now)
    end

    def limit_amount(warning_object, user)
      Notification.create(title: I18n.t('warnings.limit.amount.title', user: user.entity.tag),
                          message: I18n.t('warnings.limit.amount.message',
                                     warning_object_id: warning_object.object.id),
                          notification_type: Notification::WARNING,
                          date: DateTime.now)
    end

    def execution_date(warning_object, user)
      Notification.create(title: I18n.t('warnings.date.title', user: user.entity.tag),
                          message: I18n.t('warnings.date.message',
                                          warning_object_id: warning_object.object.id,
                                          warning_object_tag: warning_object.object.tag,
                                          warning_object_date: warning_object.object.execution_date,
                                          fact_id: warning_object.fact.id,
                                          fact_date: warning_object.fact.day),
                          notification_type: Notification::WARNING,
                          date: DateTime.now)
    end

    def compensation_period(warning_object, user)
      date = warning_object.object.execution_date + warning_object.object.compensation_period
      Notification.create(title: I18n.t('warnings.date.title', user: user.entity.tag),
                          message: I18n.t('warnings.date.message',
                                          warning_object_id: warning_object.object.id,
                                          warning_object_tag: warning_object.object.tag,
                                          warning_object_date: date,
                                          fact_id: warning_object.fact.id,
                                          fact_date: warning_object.fact.day),
                          notification_type: Notification::WARNING,
                          date: DateTime.now)
    end
  end
end
