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
      include ActiveSupport::Callbacks

      after_save :open_state
      define_callbacks :apply, :cancel, :reverse, only: [:before, :after],
                       terminator: "result == false"
    end

    def after_apply(*filters)
      set_callback :apply, :after, *filters
    end

    def after_cancel(*filters)
      set_callback :cancel, :after, *filters
    end

    def after_reverse(*filters)
      set_callback :reverse, :after, *filters
    end

    def before_apply(*filters)
      set_callback :apply, :before, *filters
    end

    def before_reverse(*filters)
      set_callback :reverse, :before, *filters
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
      return run_callbacks :cancel do
        self.deal.deal_state.close
      end
    elsif self.state == APPLIED
      return run_callbacks :reverse
    end
    false
  end

  def apply
    if self.state == INWORK
      return run_callbacks :apply do
        self.deal.deal_state.close
      end
    end
    false
  end

  def can_apply?
    self.state == INWORK
  end

  def can_cancel?
    self.state == APPLIED || self.state == INWORK
  end
end
