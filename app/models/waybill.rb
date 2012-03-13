# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Waybill < ActiveRecord::Base
  has_paper_trail

  validates :document_id, :distributor, :distributor_place, :storekeeper,
            :storekeeper_place, :created, :presence => true
  validates_uniqueness_of :document_id
  belongs_to :distributor, :polymorphic => true
  belongs_to :storekeeper, :polymorphic => true
  belongs_to :distributor_place, :class_name => 'Place'
  belongs_to :storekeeper_place, :class_name => 'Place'

  attr_reader :items

  after_initialize :do_after_initialize
  before_save :do_before_save

  def add_item(tag, mu, amount, price)
    resource = Asset.find_by_tag_and_mu(tag, mu)
    resource = Asset.new(:tag => tag, :mu => mu) if resource.nil?
    @items << WaybillItem.new(resource, amount, price)
  end

  private
  def do_after_initialize
    @items = Array.new
  end

  def do_before_save
    @items.each { |item| return false unless item.resource.save }
  end
end

class WaybillItem
  attr_reader :resource, :amount, :price

  def initialize(resource, amount, price)
    @resource = resource
    @amount = amount
    @price = price
  end
end
