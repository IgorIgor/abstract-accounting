# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Statable
  extend ActiveSupport::Concern

  module ClassMethods
    def act_as_statable
      validates_presence_of :state

      after_initialize :state_initialize
      before_save :state_change
      class_attribute :after_apply_callback
      class_attribute :after_reverse_callback
    end

    def after_apply(callback)
      self.after_apply_callback = callback
    end

    def after_reverse(callback)
      self.after_reverse_callback = callback
    end
  end

  UNKNOWN = 0
  INWORK = 1
  CANCELED = 2
  APPLIED = 3
  REVERSED = 4

  def state_initialize
    self.state = UNKNOWN if self.new_record?
  end

  def state_change
    self.state = INWORK if self.state == UNKNOWN && self.new_record?
  end

  def cancel
    if self.state == INWORK
      self.state = CANCELED
      return self.save
    elsif self.state == APPLIED
      fact = Fact.create(amount: -1.0, resource: self.deal.give.resource,
                         day: DateTime.current.change(hour: 12), to: self.deal)
      return false if fact.nil?
      self.state = REVERSED
      return false if self.class.after_reverse_callback &&
                      !send(self.class.after_reverse_callback, fact)
      return self.save
    end
    false
  end

  def apply
    if self.state == INWORK and !self.deal.nil?
      fact = Fact.create(amount: 1.0, resource: self.deal.give.resource,
                         day: DateTime.current.change(hour: 12), to: self.deal)
      return false if fact.nil?
      self.state = APPLIED
      return false if self.class.after_apply_callback &&
                      !send(self.class.after_apply_callback, fact)
      return self.save
    end
    false
  end
end
