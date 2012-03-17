# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillsController < ApplicationController
  def preview
    render "waybills/preview", :layout => false
  end

  def new
    @waybill = Waybill.new
  end

  def create
    begin
      Waybill.transaction do
        Chart.create!(:currency => Money.create!(:alpha_code => "RUB",
                                                 :num_code => 222)) unless Chart.count > 0
        params[:waybill_object][:distributor_type] = "LegalEntity"
        params[:waybill_object][:storekeeper_type] = "Entity"
        waybill = Waybill.new(params[:waybill_object])
        if waybill.distributor_id.zero?
          country = Country.find_or_create_by_tag(:tag => "Russian Federation")
          distributor = LegalEntity.find_all_by_name_and_country_id(
            params[:distributor][:name], country).first
          if distributor.nil?
            distributor = LegalEntity.new(params[:distributor])
            distributor.country = country
            distributor.save!
          end
          waybill.distributor = distributor
        end
        if waybill.distributor_place_id.zero?
          distributor_place = Place.find_or_create_by_tag(params[:distributor_place])
          distributor_place.save!
          waybill.distributor_place = distributor_place
        end
        if waybill.storekeeper_id.zero?
          storekeeper = Entity.find_or_create_by_tag(params[:storekeeper])
          storekeeper.save!
          waybill.storekeeper = storekeeper
        end
        if waybill.storekeeper_place_id.zero?
          storekeeper_place = Place.find_or_create_by_tag(params[:storekeeper_place])
          storekeeper_place.save!
          waybill.storekeeper_place = storekeeper_place
        end
        params[:items].each_value { |item|
          waybill.add_item(item[:tag], item[:mu], item[:count].to_f, item[:price].to_f)
        }
        waybill.save!
        render :text => "success"
      end
    rescue
      render :text => "errors"
    end
  end

end
