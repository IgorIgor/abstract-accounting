# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DealState < ActiveRecord::Base
  has_paper_trail

  UNKNOWN = 0
  INWORK = 1
  CANCELED = 2
  APPLIED = 3
  REVERSED = 4

  attr_accessible :deal_id
  belongs_to :deal

  validates_uniqueness_of :deal_id
  validates_inclusion_of :state, in: [UNKNOWN, INWORK, CANCELED, APPLIED, REVERSED]

  before_save :set_open
  after_initialize :set_deafault_state

  def unknown?
    !self.opened && !self.closed && !self.reversed
  end

  def in_work?
    !!self.opened && !self.closed && !self.reversed
  end

  def closed?
    !!self.opened && !!self.closed && !self.reversed
  end

  def reversed?
    !!self.opened && !!self.closed && !!self.reversed
  end

  def apply
    return false if self.state != INWORK || !close
    self.state = APPLIED
    self.save
  end

  def cancel
    return false if self.state != INWORK || !close
    self.state = CANCELED
    self.save
  end

  def reverse
    return false if self.state != APPLIED || reversed?
    self.reversed = Date.today
    self.state = REVERSED
    self.save
  end

  def can_apply?
    in_work? && state == INWORK
  end

  def can_cancel?
    in_work? && state == INWORK
  end

  def can_reverse?
    closed? && state == APPLIED
  end

  private
    def set_open
      if self.new_record?
        self.opened = Date.today
        self.state = INWORK
      end
      true
    end

    def set_deafault_state
      self.state ||= UNKNOWN
    end

    def close
      return false if self.closed?
      self.closed = Date.today
      true
    end
end
