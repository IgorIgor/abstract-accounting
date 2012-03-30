# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DistributionsController < ApplicationController
  def preview
    render "distributions/preview", :layout => false
  end

  def new
    @distribution = Distribution.new
  end

  def create
    distribution = nil
    begin
      Distribution.transaction do
        Chart.create!(:currency => Money.create!(:alpha_code => "RUB",
                                                 :num_code => 222)) unless Chart.count > 0
        params[:object][:storekeeper_type] = "Entity"
        params[:object][:foreman_type] = "Entity"
        distribution = Distribution.new(params[:object])
        if distribution.storekeeper_id.zero?
          storekeeper = Entity.find_or_create_by_tag(params[:storekeeper])
          storekeeper.save!
          distribution.storekeeper = storekeeper
        end
        if distribution.storekeeper_place_id.zero?
          storekeeper_place = Place.find_or_create_by_tag(params[:storekeeper_place])
          storekeeper_place.save!
          distribution.storekeeper_place = storekeeper_place
        end
        if distribution.foreman_id.zero?
          foreman = Entity.find_or_create_by_tag(params[:foreman])
          foreman.save!
          distribution.foreman = foreman
        end
        if distribution.foreman_place_id.zero?
          foreman_place = Place.find_or_create_by_tag(params[:foreman_place])
          foreman_place.save!
          distribution.foreman_place = foreman_place
        end
        params[:items].each_value { |item|
          distribution.add_item(item[:tag], item[:mu], item[:amount].to_f)
        } if params[:items]
        distribution.save!
        render :text => "success"
      end
    rescue
      render json: distribution.errors.messages
    end
  end

  def show
    @distribution = Distribution.find(params[:id])

    respond_to { |format|
      format.html { render :show, layout: false }
      format.json
      format.pdf {
        render pdf: 'distribution',
               template: 'distributions/show.html.erb',
               encoding: 'utf-8',
               layout: false
      }
    }
  end

  def apply
    distribution = Distribution.find(params[:id])
    if distribution.apply
      render :text => "success"
    else
      render json: distribution.errors.messages
    end
  end

  def cancel
    distribution = Distribution.find(params[:id])
    if distribution.cancel
      render :text => "success"
    else
      render json: distribution.errors.messages
    end
  end

end
