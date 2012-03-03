# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class EstimatesController < ApplicationController
  def preview
    render "estimates/preview", :layout => false
  end

  def new
    @estimate = Estimate.new
  end

  def create
    begin
      Estimate.transaction do
        Chart.create!(:currency => Money.create!(:alpha_code => "RUB",
          :num_code => 222)) unless Chart.count > 0
        estimate = Estimate.new(params[:object])
        unless estimate.legal_entity
          legal_entity = LegalEntity.new(params[:legal_entity])
          legal_entity.country = Country.find_or_create_by_tag(:tag => "Russian Federation")
          legal_entity.save!
          estimate.legal_entity = legal_entity
        end
        p estimate
        estimate.save!
        params[:boms].each_value { |bom|
          estimate.items.create!(bom)
          p bom
        }
        render :text => "success"
      end
    rescue
      render json: estimate.errors
    end
  end

  def index
    @estimates = Estimate.all
  end

  def show
    @estimate = Estimate.find(params[:id])
  end

  def update
    estimate = Estimate.find(params[:object][:id])
    begin
      Estimate.transaction do
        estimate.catalog_id = params[:object][:catalog_id]
        estimate.legal_entity_id = params[:object][:legal_entity_id]
        unless estimate.legal_entity
          legal_entity = LegalEntity.new(params[:legal_entity])
          legal_entity.country = Country.find_or_create_by_tag(:tag => "Russian Federation")
          legal_entity.save!
          estimate.legal_entity = legal_entity
        end
        estimate.save!
        items = []
        params[:boms].each { |idx, bom|
          idx = idx.to_i
          items << estimate.items.select { |item|
            item[:bom_id].to_s == bom[:bom_id].to_s
          }.first
          if items[idx].nil?
            items[idx] = EstimateElement.create!(:estimate => estimate,
                                                 :bom_id => bom[:bom_id],
                                                 :amount => bom[:amount])
          else
            items[idx].update_attributes(:amount => bom[:amount])
          end
        }
        estimate.items = items
        render :text => "success"
      end
    rescue
      render :json => estimate.errors.messages
    end
  end
end
