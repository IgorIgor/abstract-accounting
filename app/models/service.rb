# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Service < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :tag, :mu
  validates_uniqueness_of :tag, :scope => :mu
  belongs_to :detailed, :class_name => "DetailedService"
  has_many :terms, :as => :resource
  # TODO: fix direct access to side
  has_many :terms_as_give, :class_name => Term, :as => :resource, :conditions => { :side => false }
  has_many :terms_as_take, :class_name => Term, :as => :resource, :conditions => { :side => true }
  has_many :deal_gives, :class_name => "Deal", :through => :terms_as_give, :source => :deal
  has_many :deal_takes, :class_name => "Deal", :through => :terms_as_take, :source => :deal
end
