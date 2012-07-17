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
    render 'preview'
  end

  def index
    render 'index', layout: false
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
        params[:allocation][:storekeeper_type] = "Entity"
        params[:allocation][:foreman_type] = "Entity"
        params[:allocation].delete(:state) if params[:allocation].has_key?(:state)
        allocation = Allocation.new(params[:allocation])
        unless allocation.storekeeper
          storekeeper = Entity.find_or_create_by_tag(params[:storekeeper])
          storekeeper.save!
          allocation.storekeeper = storekeeper
        end
        unless allocation.storekeeper_place
          storekeeper_place = Place.find_or_create_by_tag(params[:storekeeper_place])
          storekeeper_place.save!
          allocation.storekeeper_place = storekeeper_place
        end
        unless allocation.foreman
          foreman = Entity.find_or_create_by_tag(params[:foreman])
          foreman.save!
          allocation.foreman = foreman
        end
        unless allocation.foreman_place
          foreman_place = Place.find_or_create_by_tag(params[:foreman_place])
          foreman_place.save!
          allocation.foreman_place = foreman_place
        end
        params[:items].each_value { |item| allocation.add_item(item) } if params[:items]
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
        render pdf: 'allocations.show.html.erb',
               :formats => [:html],
               encoding: 'utf-8',
               layout: false
      }
    }
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i

    scope = Allocation
    unless current_user.root?
      credential = current_user.credentials(:force_update).
                                where{document_type == Waybill.name}.first
      if credential
        scope = scope.by_storekeeper(current_user.entity).
                      by_storekeeper_place(credential.place)
      else
        scope = scope.where{id == nil}
      end
    end
    scope_count = scope
    scope = scope.order_by(params[:order]) if params[:order]
    @allocations = scope.limit(per_page).offset((page - 1) * per_page)
    @count = scope_count.count
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

  def resources
    allocation = Allocation.find(params[:id])
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    @resources = allocation.items[(page - 1) * per_page, per_page]
    @count = allocation.items.count
  end

end
