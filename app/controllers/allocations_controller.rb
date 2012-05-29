# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
require "waybill"

class AllocationsController < ApplicationController
  layout 'comments'

  def preview
    render 'allocations/preview'
  end

  def new
    @allocation = Allocation.new
    unless current_user.root?
      credential = current_user.credentials.where(document_type: Allocation.name).first
      if credential
        @allocation.storekeeper = current_user.entity
        @allocation.storekeeper_place = credential.place
      end
    end
  end

  def create
    allocation = nil
    begin
      Allocation.transaction do
        Chart.create!(:currency => Money.create!(:alpha_code => "RUB",
                                                 :num_code => 222)) unless Chart.count > 0
        params[:allocation][:storekeeper_type] = "Entity"
        params[:allocation][:foreman_type] = "Entity"
        params[:allocation].delete(:state) if params[:allocation].has_key?(:state)
        allocation = Allocation.new(params[:allocation])
        if allocation.storekeeper_id.zero?
          storekeeper = Entity.find_or_create_by_tag(params[:storekeeper])
          storekeeper.save!
          allocation.storekeeper = storekeeper
        end
        if allocation.storekeeper_place_id.zero?
          storekeeper_place = Place.find_or_create_by_tag(params[:storekeeper_place])
          storekeeper_place.save!
          allocation.storekeeper_place = storekeeper_place
        end
        if allocation.foreman_id.zero?
          foreman = Entity.find_or_create_by_tag(params[:foreman])
          foreman.save!
          allocation.foreman = foreman
        end
        if allocation.foreman_place_id.zero?
          foreman_place = Place.find_or_create_by_tag(params[:foreman_place])
          foreman_place.save!
          allocation.foreman_place = foreman_place
        end
        params[:items].each_value { |item|
          allocation.add_item(item[:tag], item[:mu], item[:amount].to_f)
        } if params[:items]
        allocation.save!
        render :text => "success"
      end
    rescue
      render json: allocation.errors.messages
    end
  end

  def show
    @allocation = Allocation.find(params[:id])

    respond_to { |format|
      format.html { render :show, layout: false }
      format.json
      format.pdf {
        render pdf: 'allocation',
               template: 'allocations/show.html.erb',
               encoding: 'utf-8',
               layout: false
      }
    }
  end

  def apply
    allocation = Allocation.find(params[:id])
    if allocation.apply
      render :text => "success"
    else
      render json: allocation.errors.messages
    end
  end

  def cancel
    allocation = Allocation.find(params[:id])
    if allocation.cancel
      render :text => "success"
    else
      render json: allocation.errors.messages
    end
  end

end
