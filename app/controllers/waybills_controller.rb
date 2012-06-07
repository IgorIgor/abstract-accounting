# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillsController < ApplicationController
  layout 'comments'

  def preview
    render 'waybills/preview'
  end

  def new
    @waybill = Waybill.new
    unless current_user.root?
      credential = current_user.credentials.where(document_type: Waybill.name).first
      if credential
        @waybill.storekeeper = current_user.entity
        @waybill.storekeeper_place = credential.place
      end
    end
  end

  def create
    waybill = nil
    begin
      Waybill.transaction do
        Chart.create!(:currency => Money.create!(:alpha_code => "RUB",
                                                 :num_code => 222)) unless Chart.count > 0
        params[:waybill][:distributor_type] = "LegalEntity"
        params[:waybill][:storekeeper_type] = "Entity"
        waybill = Waybill.new(params[:waybill])
        unless waybill.distributor
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
        unless waybill.distributor_place
          distributor_place = Place.find_or_create_by_tag(params[:distributor_place])
          distributor_place.save!
          waybill.distributor_place = distributor_place
        end
        unless waybill.storekeeper
          storekeeper = Entity.find_or_create_by_tag(params[:storekeeper])
          storekeeper.save!
          waybill.storekeeper = storekeeper
        end
        unless waybill.storekeeper_place
          storekeeper_place = Place.find_or_create_by_tag(params[:storekeeper_place])
          storekeeper_place.save!
          waybill.storekeeper_place = storekeeper_place
        end
        params[:items].each_value { |item| waybill.add_item(item) } if params[:items]
        waybill.save!
        render :text => "success"
      end
    rescue
      render json: waybill.errors.full_messages
    end
  end

  def show
    @waybill = Waybill.find(params[:id])
  end

  def data
    attrs = {}

    if params.has_key?(:equal)
      params[:equal].each do |key, value|
        unless value.empty?
          attrs[:where] ||= {}
          attrs[:where][key] = {}
          attrs[:where][key][:equal] = value
        end
      end
    end

    attrs[:without_waybills] =
      params[:without] if params.has_key?(:without)

    @waybills = Waybill.in_warehouse(attrs)
  end

  def resources
    @resources = Waybill.find(params[:id]).items
  end

  def apply
    waybill = Waybill.find(params[:id])
    if waybill.apply
      render :text => "success"
    else
      render json: waybill.errors.full_messages
    end
  end

  def cancel
    waybill = Waybill.find(params[:id])
    if waybill.cancel
      render :text => "success"
    else
      render json: waybill.errors.full_messages
    end
  end
end
