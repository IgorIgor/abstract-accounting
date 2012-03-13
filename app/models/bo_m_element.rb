# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class BoMElement < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :resource_id, :bom_id, :rate
  belongs_to :resource, :class_name => "Asset"
  belongs_to :bom, :class_name => "BoM"

  def sum(price, physical_amount)
    self.rate * price.rate * physical_amount
  end

  def to_rule(deal, place, price, physical_amount)
    deal.rules.create!(:tag => "deal rule ##{deal.rules.count() + 1}",
                       :from => convertation_deal(deal.entity, place),
                       :to => money_storage(deal.entity, place),
                       :rate => sum(price, physical_amount),
                       :fact_side => false, :change_side => true)
  end

  private
  def money_storage(entity, place)
    find_or_create_deal("storage from #{Chart.first.currency.alpha_code} to #{Chart.first.currency.alpha_code}",
                        entity, place, Chart.first.currency, Chart.first.currency, 1.0)
  end

  def convertation_deal(entity, place)
    find_or_create_deal("resource converter from #{resource.tag} to #{Chart.first.currency.alpha_code}",
                        entity, place, self.resource, Chart.first.currency, self.rate)
  end

  def find_or_create_deal(tag, entity, place, give, take, rate)
    deal = Deal.where(:entity_id => entity.id, :entity_type => entity.class).
                where(:tag => tag).first
    if deal.nil?
      deal = Deal.new(:tag => tag, :rate => rate, :entity => entity)
      deal.build_give(:resource => give, :place => place)
      deal.build_take(:resource => take, :place => place)
      deal.save!
    end
    deal
  end
end
