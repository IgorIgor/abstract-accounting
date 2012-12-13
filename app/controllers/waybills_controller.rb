# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "helpers/state_change"

class WaybillsController < ApplicationController
  authorize_resource class: Waybill.name
  layout 'comments'

  include Helpers::StateChange
  act_as_statable Waybill

  def index
    render 'index', layout: "data_with_filter"
  end

  def preview
    render 'preview'
  end

  def new
    @waybill = Waybill.new
  end

  def create
    waybill = nil
    begin
      Waybill.transaction do
        distributor_type = params[:waybill][:distributor_type]
        params[:waybill].delete(:state) if params[:waybill].has_key?(:state)
        params[:waybill].merge!(Waybill.extract_warehouse(params[:waybill][:warehouse_id]))
        params[:waybill].delete(:warehouse_id)
        params[:waybill][:created] = DateTime.parse(params[:waybill][:created]).
                                              change(hour: 12, offset: 0)
        waybill = Waybill.new(params[:waybill])
        unless waybill.distributor
          distributor = nil
          if distributor_type == LegalEntity.name
            country = Country.find_or_create_by_tag(
                I18n.t("activerecord.attributes.country.default.tag")
            )
            distributor = LegalEntity.find_all_by_name_and_country_id(
              params[:legal_entity][:name], country).first
            if distributor.nil?
              distributor = LegalEntity.new(params[:legal_entity])
              distributor.country = country
              distributor.save!
            end
          else
            distributor = Entity.find_by_tag(params[:entity][:tag])
            if distributor.nil?
              distributor = Entity.new(params[:entity])
              distributor.save!
            end
          end
          waybill.distributor = distributor
        end
        unless waybill.distributor_place
          distributor_place = Place.find_or_create_by_tag(params[:distributor_place])
          distributor_place.save!
          waybill.distributor_place = distributor_place
        end
        params[:items].each_value { |item| waybill.add_item(item) } if params[:items]
        waybill.save!
        render json: { result: 'success', id: waybill.id }
      end
    rescue
      render json: waybill.errors.full_messages
    end
  end

  def update
    waybill = Waybill.find(params[:id])
    begin
      Waybill.transaction do
        params[:waybill][:created] = DateTime.parse(params[:waybill][:created]).
            change(hour: 12, offset: 0)
        params[:waybill].delete(:state) if params[:waybill].has_key?(:state)
        params[:waybill].merge!(Waybill.extract_warehouse(params[:waybill][:warehouse_id]))
        params[:waybill].delete(:warehouse_id)

        distributor_type = params[:waybill][:distributor_type]
        unless (waybill.distributor.id == params[:waybill][:distributor_id].to_i) &&
            (waybill.distributor.class.name == distributor_type)
          distributor = nil
          if distributor_type == LegalEntity.name
            params.delete(:entity) if params.has_key?(:entity)
            country = Country.find_or_create_by_tag(
                I18n.t("activerecord.attributes.country.default.tag")
            )
            distributor = LegalEntity.find_all_by_name_and_country_id(
              params[:legal_entity][:name], country).first
            if distributor.nil?
              distributor = LegalEntity.new(params[:legal_entity])
              distributor.country = country
              distributor.save!
            end
          else
            params.delete(:legal_entity) if params.has_key?(:legal_entity)
            distributor = Entity.find_by_tag(params[:entity][:tag])
            if distributor.nil?
              distributor = Entity.new(params[:entity])
              distributor.save!
            end
          end
          waybill.distributor = distributor
          params[:waybill][:distributor_id] = distributor.id
          params[:waybill][:distributor_type] = distributor_type
        end

        unless waybill.distributor_place.id == params[:waybill][:distributor_place_id].to_i
          waybill.distributor_place = Place.find_or_create_by_tag(params[:distributor_place])
          params[:waybill][:distributor_place_id] = waybill.distributor_place.id
        end

        waybill.items.clear

        params[:items].each_value { |item| waybill.add_item(item) } if params[:items]

        waybill.update_attributes(params[:waybill])

        render json: { result: 'success', id: waybill.id }
      end
    rescue
      render json: waybill.errors.full_messages
    end
  end

  def show
    @waybill = Waybill.find(params[:id])
  end

  def present
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i

    scope = autorize_warehouse(Waybill)
    if scope
      scope = scope.
          by_warehouse(Place.find(params[:warehouse_id])) if params.has_key?(:warehouse_id)
      scope = scope.without(params[:without]) if params.has_key?(:without)
      scope = scope.search(params[:search]) if params[:search]
      scope = scope.in_warehouse
      @count = SqlRecord.from(scope.to_sql).count
      @count = @count.length unless @count.instance_of? Fixnum
      scope = scope.order_by(params[:order]) if params[:order]
      @waybills = scope.limit(per_page).offset((page - 1) * per_page).includes_all
    else
      @count = 0
      @waybills = []
    end
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i

    scope = autorize_warehouse(Waybill)
    if scope
      filter = {}
      filter[:sort] = params[:order] if params[:order]
      if params[:search] && params[:search][:states]
        states = {inwork: false, canceled: false, applied: false, reversed: false}
        states[:inwork] = true if params[:search][:states].include? Waybill::INWORK.to_s
        states[:canceled] = true if params[:search][:states].include? Waybill::CANCELED.to_s
        states[:applied] = true if params[:search][:states].include? Waybill::APPLIED.to_s
        states[:reversed] = true if params[:search][:states].include? Waybill::REVERSED.to_s
        filter[:search] = {:states => states}

      else
        filter[:search] = {states: {inwork: true, canceled: true, applied: true, reversed: false}}
      end
      scope = scope.filtrate(filter)
      @count = scope.count
      @count = @count.length unless @count.instance_of? Fixnum
      @waybills = scope.paginate({ page: page, per_page: per_page })
      @total = scope.total
    else
      @count = 0
      @total = 0.0
      @waybills = []
    end
  end

  def list
    respond_to do |format|
      format.html { render :'waybills/list', layout: 'data_with_filter' }
      format.json do
        page = params[:page].nil? ? 1 : params[:page].to_i
        per_page = params[:per_page].nil? ?
            Settings.root.per_page.to_i : params[:per_page].to_i

        scope = autorize_warehouse(WaybillReport, alias: Waybill)
        if scope
          scope = scope.with_resources

          filter = {}
          filter[:sort] = params[:order] if params[:order]
          filter[:search] = params[:search] if params[:search]

          if params[:search] && params[:search][:states]
            states = {inwork: false, canceled: false, applied: false, reversed: false}
            states[:inwork] = true if params[:search][:states].include? Waybill::INWORK.to_s
            states[:canceled] = true if params[:search][:states].include? Waybill::CANCELED.to_s
            states[:applied] = true if params[:search][:states].include? Waybill::APPLIED.to_s
            states[:reversed] = true if params[:search][:states].include? Waybill::REVERSED.to_s
            filter[:search] = {:states => states}
          else
            filter[:search] = {states: {inwork: true, canceled: true, applied: true, reversed: false}}
          end
          scope = scope.filtrate(filter)
          @count = scope.count
          @count = @count.size if @count.kind_of? Hash
          @total = scope.total
          @list = scope.paginate({ page: page, per_page: per_page }).select_all.includes_all
        else
          @count = 0
          @total = 0.0
          @list = []
        end
      end
    end
  end

  def resources
    waybill = Waybill.find(params[:id])
    @exp_amount = params[:exp_amount]
    @resources = []
    if params[:all]
      @resources = waybill.items
    else
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i
      @resources = waybill.items[(page - 1) * per_page, per_page]
    end
    @count = waybill.items.count
  end
end
