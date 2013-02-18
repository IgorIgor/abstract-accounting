# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Project < Base
    validates_presence_of :place_id, :customer_id, :customer_type, :boms_catalog_id,
                          :prices_catalog_id
    belongs_to :customer, polymorphic: true
    belongs_to :place
    belongs_to :boms_catalog, class_name: Estimate::Catalog
    belongs_to :prices_catalog, class_name: Estimate::Catalog

    has_many :locals

    include Helpers::Commentable
    has_comments

    custom_sort(:customer_tag) do |dir|
      query = "case customer_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
      joins{customer(Entity).outer}.joins{customer(LegalEntity).outer}.order("#{query} #{dir}")
    end

    custom_sort(:place_tag) do |dir|
      joins{place}.order("places.tag #{dir}")
    end

    def self.build_params params
      if params[:project][:customer_id]
        customer_id = params[:project][:customer_id]
      else
        if params[:project][:customer_type] == LegalEntity.name
          country = Country.find_or_create_by_tag(
              I18n.t("activerecord.attributes.country.default.tag")
          )
          customer = LegalEntity.find_by_name_and_country_id(
              params[:project][:legal_entity][:tag], country)
          if customer.nil?
            customer_id = LegalEntity.create(
                tag: params[:project][:legal_entity][:tag],
                identifier_value: params[:project][:legal_entity][:identifier_value],
                identifier_name: 'vatin',
                country: country
            ).id
          else
            customer_id = customer.id
          end
        else
          customer_id = Entity.find_or_create_by_tag(params[:project][:entity][:tag]).id
        end
      end
      if params[:project][:place_id]
        place_id = params[:project][:place_id]
      else
        place_id = Place.find_or_create_by_tag(params[:project][:place][:tag]).id
      end
      {
          place_id: place_id,
          customer_id: customer_id,
          customer_type: params[:project][:customer_type],
          boms_catalog_id: params[:project][:boms_catalog][:id],
          prices_catalog_id: params[:project][:prices_catalog][:id]
      }
    end
  end
end
