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
      after_save :open_state
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

  def open_state
    self.deal.create_deal_state! if self.deal.deal_state.nil?
  end

  def state
    return UNKNOWN if self.deal.nil? || self.deal.deal_state(:force).nil?
    if self.deal.deal_state.in_work?
      return INWORK
    elsif self.deal.deal_state.closed? && Fact.where{to_deal_id == my{deal_id}}.count == 0
      return CANCELED
    elsif self.deal.deal_state.closed? &&
        Fact.where{to_deal_id == my{deal_id}}.count == 1 &&
        Fact.where{to_deal_id == my{deal_id}}.where{amount == 1.0}.count == 1
      return APPLIED
    elsif self.deal.deal_state.closed? && Fact.where{to_deal_id == my{deal_id}}.count == 2 &&
            Fact.where{to_deal_id == my{deal_id}}.where{amount == -1.0}.count == 1
      return REVERSED
    end
    UNKNOWN
  end

  def cancel
    if self.state == INWORK
      return self.deal.deal_state.close
    elsif self.state == APPLIED
      fact = Fact.create(amount: -1.0, resource: self.deal.give.resource,
                         day: DateTime.current.change(hour: 12), to: self.deal)
      return false if fact.nil?
      return false if self.class.after_reverse_callback &&
                      !send(self.class.after_reverse_callback, fact)
      return true
    end
    false
  end

  def apply
    if self.state == INWORK
      fact = Fact.create(amount: 1.0, resource: self.deal.give.resource,
                         day: DateTime.current.change(hour: 12), to: self.deal)
      return false if fact.nil?
      return false if self.class.after_apply_callback &&
                      !send(self.class.after_apply_callback, fact)
      return self.deal.deal_state.close
    end
    false
  end
end
