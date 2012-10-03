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
        params[:waybill][:distributor_type] = LegalEntity.name
        params[:waybill].delete(:state) if params[:waybill].has_key?(:state)
        params[:waybill].merge!(Waybill.extract_warehouse(params[:waybill][:warehouse_id]))
        params[:waybill].delete(:warehouse_id)
        params[:waybill][:created] = DateTime.parse(params[:waybill][:created]).
                                              change(offset: 0)
        waybill = Waybill.new(params[:waybill])
        unless waybill.distributor
          country = Country.find_or_create_by_tag(
              I18n.t("activerecord.attributes.country.default.tag")
          )
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
        params[:items].each_value { |item| waybill.add_item(item) } if params[:items]
        waybill.save!
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
      scope = scope.search(params[:search]) if params[:search]
      @count = scope.count
      @count = @count.length unless @count.instance_of? Fixnum
      @total = scope.total
      scope = scope.order_by(params[:order]) if params[:order]
      @waybills = scope.limit(per_page).offset((page - 1) * per_page).includes_all
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
          scope = scope.search(params[:search]) if params[:search]
          @count = scope.count
          unless @count.instance_of? Fixnum
            @count = @count.values[0]
          end
          @total = scope.total
          scope = scope.order_by(params[:order]) if params[:order]
          @list = scope.limit(per_page).offset((page - 1) * per_page).select_all.
              includes_all
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
