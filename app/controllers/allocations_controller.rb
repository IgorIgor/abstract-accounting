# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
require "waybill"
require "helpers/state_change"

class AllocationsController < ApplicationController
  authorize_resource class: Allocation.name
  layout 'comments'

  include Helpers::StateChange
  act_as_statable Allocation

  def preview
    render 'preview'
  end

  def index
    render 'index', layout: "data_with_filter"
  end

  def new
    @allocation = Allocation.new
  end

  def create
    allocation = nil
    begin
      Allocation.transaction do
        params[:allocation][:foreman_type] = "Entity" if params[:allocation][:foreman_id]
        params[:allocation].delete(:state) if params[:allocation].has_key?(:state)
        params[:allocation].merge!(
            Allocation.extract_warehouse(params[:allocation][:warehouse_id]))
        params[:allocation].delete(:warehouse_id)
        params[:allocation][:created] = DateTime.parse(params[:allocation][:created]).
                                                 change(hour: 12, offset: 0)
        allocation = Allocation.new(params[:allocation])
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
        render json: { result: 'success', id: allocation.id }
      end
    rescue
      render json: allocation.errors.full_messages
    end
  end

  def update
    allocation = Allocation.find(params[:id])
    begin
      Allocation.transaction do
        params[:allocation][:created] = DateTime.parse(params[:allocation][:created]).change(hour: 12, offset: 0)
        params[:allocation][:foreman_type] = "Entity" if params[:allocation][:foreman_id]
        params[:allocation].delete(:state) if params[:allocation].has_key?(:state)
        params[:allocation].merge!(
            Allocation.extract_warehouse(params[:allocation][:warehouse_id]))
        params[:allocation].delete(:warehouse_id)

        unless allocation.foreman.id == params[:allocation][:foreman_id].to_i
          allocation.foreman = Entity.find_or_create_by_tag(params[:foreman])
          params[:allocation][:foreman_id] = allocation.foreman.id
          params[:allocation][:foreman_type] = allocation.foreman.class.name
        end
        unless allocation.foreman_place.id == params[:allocation][:foreman_place_id].to_i
          allocation.foreman_place = Place.find_or_create_by_tag(params[:foreman_place])
          params[:allocation][:foreman_place_id] = allocation.foreman_place.id
        end

        allocation.items.clear

        params[:items].each_value { |item| allocation.add_item(item) } if params[:items]

        allocation.update_attributes(params[:allocation])

        render json: { result: 'success', id: allocation.id }
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

    scope = autorize_warehouse(Allocation)
    if scope
      filter = {}
      filter[:sort] = params[:order] if params[:order]

      if params[:search] && params[:search][:states]
        states = {inwork: false, canceled: false, applied: false, reversed: false}
        states[:inwork] = true if params[:search][:states].include? Allocation::INWORK.to_s
        states[:canceled] = true if params[:search][:states].include? Allocation::CANCELED.to_s
        states[:applied] = true if params[:search][:states].include? Allocation::APPLIED.to_s
        states[:reversed] = true if params[:search][:states].include? Allocation::REVERSED.to_s
        filter[:search] = {:states => states}
      else
        filter[:search] = {states: {inwork: true, canceled: true, applied: true, reversed: false}}
      end
      scope = scope.filtrate(filter)
      @count = scope.count
      @count = @count.count unless @count.instance_of? Fixnum
      @allocations = scope.paginate({ page: page, per_page: per_page })
    else
      @count = 0
      @allocations = []
    end
  end

  def list
    respond_to do |format|
      format.html { render :'allocations/list', layout: 'data_with_filter' }
      format.json do
        page = params[:page].nil? ? 1 : params[:page].to_i
        per_page = params[:per_page].nil? ?
            Settings.root.per_page.to_i : params[:per_page].to_i

        scope = autorize_warehouse(AllocationReport, alias: Allocation)
        if scope
          scope = scope.with_resources

          filter = {}
          filter[:sort] = params[:order] if params[:order]
          filter[:search] = params[:search] if params[:search]

          if params[:search] && params[:search][:states]
            states = {inwork: false, canceled: false, applied: false, reversed: false}
            states[:inwork] = true if params[:search][:states].include? Allocation::INWORK.to_s
            states[:canceled] = true if params[:search][:states].include? Allocation::CANCELED.to_s
            states[:applied] = true if params[:search][:states].include? Allocation::APPLIED.to_s
            states[:reversed] = true if params[:search][:states].include? Allocation::REVERSED.to_s
            filter[:search] = {:states => states}
          else
            filter[:search] = {states: {inwork: true, canceled: true, applied: true, reversed: false}}
          end
          scope = scope.filtrate(filter)

          @count = scope.count
          unless @count.instance_of? Fixnum
            @count = @count.values[0]
          end
          @list = scope.paginate({ page: page, per_page: per_page }).select_all.includes_all
        else
          @count = 0
          @list = []
        end
      end
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
