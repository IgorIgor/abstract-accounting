# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class BoM < Base
    has_paper_trail

    validates_presence_of :resource_id, :uid, :catalog_id
    validates_uniqueness_of :uid
    belongs_to :resource, class_name: "::#{Asset.name}"
    has_many :items, class_name: BoMElement, :foreign_key => :bom_id
    belongs_to :catalog
    has_many :builders, class_name: BoMElement, :foreign_key => :bom_id, :conditions => { :uid => '1' }
    has_many :rank, class_name: BoMElement, :foreign_key => :bom_id, :conditions => { :uid => '1.1' }
    has_many :machinist, class_name: BoMElement, :foreign_key => :bom_id, :conditions => { :uid => '2' }
    has_many :machinery, class_name: BoMElement, :foreign_key => :bom_id, :conditions => { :element_type => '3' }
    has_many :resources, class_name: BoMElement, :foreign_key => :bom_id, :conditions => { :element_type => '4' }

    BUILDERS = 1
    MACHINIST = 2
    MACHINERY = 3
    RESOURCES = 4

    def element_builders(rate,rank_rate)
      asset = Asset.find_or_create_by_tag_and_mu(I18n.t('views.estimates.elements.builders'),
                                                 I18n.t('views.estimates.elements.mu.people'))
      self.items.build(uid: 1, element_type: BUILDERS, resource_id: asset.id, rate: rate)
      asset = Asset.find_or_create_by_tag(I18n.t('views.estimates.elements.rank'))
      self.items.build(uid: 1.1, element_type: BUILDERS, resource_id: asset.id, rate: rank_rate)
    end

    def element_machinist(rate)
      asset = Asset.find_or_create_by_tag_and_mu(I18n.t('views.estimates.elements.machinist'),
                                                 I18n.t('views.estimates.elements.mu.machine'))
      self.items.build(uid: 2, element_type: MACHINIST, resource_id: asset.id, rate: rate)
    end

    def element_items(args, type)
      if args[:id]
        resource_id = args[:id]
      else
        if type == RESOURCES
          mu = args[:mu]
        else
          mu = I18n.t('views.estimates.elements.mu.machine')
        end
        asset = Asset.find_or_create_by_tag_and_mu(tag: args[:tag], mu: mu)
        resource_id = asset.id
      end
      self.items.build(uid: args[:code], element_type: type,
                        rate: args[:rate], resource_id: resource_id)
    end

    def sum(prices, physical_amount)
      self.items.reduce(0) do |sum, item|
        sum + item.sum(prices.items.where(resource_id: item.resource_id).first,
                       physical_amount)
      end
    end

    def sum_by_catalog(catalog, date, physical_amount)
      self.sum(catalog.price_list(date, self.tab), physical_amount)
    end

    def to_deal(entity, place, prices, physical_amount)
      deal = Deal.new(:tag => "estimate deal for bom: #{self.id}; ##{
      Deal.where("tag LIKE 'estimate deal for bom: #{self.id}; #%'").count() + 1
      }",
                      :entity => entity,
                      :rate => 1.0, :isOffBalance => true)
      deal.build_give(:resource => self.resource, :place => place)
      deal.build_take(:resource => self.resource, :place => place)
      deal.save!
      self.items.each do |element|
        price = prices.items.where("resource_id = ?", element.resource_id).first
        element.to_rule(deal, place, price, physical_amount)
      end
      deal
    end
  end
end
