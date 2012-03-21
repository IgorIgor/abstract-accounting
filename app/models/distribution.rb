# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'waybill'

class Distribution < ActiveRecord::Base
  has_paper_trail

  validates :foreman, :foreman_place, :storekeeper, :storekeeper_place,
            :created, :state, :presence => true

  belongs_to :deal
  belongs_to :foreman, :polymorphic => true
  belongs_to :storekeeper, :polymorphic => true
  belongs_to :foreman_place, :class_name => 'Place'
  belongs_to :storekeeper_place, :class_name => 'Place'

  after_initialize :do_after_initialize

  def add_item(tag, mu, amount)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    @items << DistributionItem.new(resource, amount)
  end

  def items
    @items
  end

  private
  def do_after_initialize
    @items = Array.new
  end
end

class DistributionItem < WaybillItem
  def initialize(resource, amount)
    @resource = resource
    @amount = amount
  end
end
