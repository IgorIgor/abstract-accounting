# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Money < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :num_code
  validates_presence_of :alpha_code
  validates_uniqueness_of :num_code
  validates_uniqueness_of :alpha_code
  has_many :quotes
  has_many :terms, :as => :resource
  # TODO: fix direct access to side
  has_many :terms_as_give, :class_name => Term, :as => :resource, :conditions => { :side => false }
  has_many :terms_as_take, :class_name => Term, :as => :resource, :conditions => { :side => true }
  has_many :deal_gives, :class_name => "Deal", :through => :terms_as_give, :source => :deal
  has_many :deal_takes, :class_name => "Deal", :through => :terms_as_take, :source => :deal
  has_many :balances_gives, :class_name => "Balance", :through => :deal_gives, :source => :balances
  has_many :balances_takes, :class_name => "Balance", :through => :deal_takes, :source => :balances

  alias_attribute :tag, :alpha_code

  def quote
    self.quotes.where(:day => self.quotes.maximum(:day)).first
  end
end

# vim: ts=2 sts=2 sw=2 et:
