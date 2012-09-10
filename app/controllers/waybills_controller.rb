# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillsController < ApplicationController
  authorize_resource class: Waybill.name
  layout 'comments'

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
    unless current_user.root?
      credential = current_user.credentials(:force_update).
          where{document_type == Waybill.name}.first
      if credential
        attrs[:where] = {} unless attrs.has_key?(:where)
        attrs[:where][:warehouse_id] = { equal: credential.place_id }
      else
        @waybills = []
        render :data
        return
      end
    end

    attrs[:without_waybills] =
      params[:without] if params.has_key?(:without)

    @waybills = Waybill.in_warehouse(attrs)

    render :data
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
      @waybills = scope.limit(per_page).offset((page - 1) * per_page).
        includes(deal: [:entity, terms: [:resource, :place],
                 rules: [from: [:entity, terms: [:resource, :place]],
                         to: [:entity, terms: [:resource, :place]]]])
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
              includes(deal: [:entity, terms: [:resource, :place],
                       rules: [from: [:entity, terms: [:resource, :place]],
                               to: [:entity, terms: [:resource, :place]]]])
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

  def apply
    waybill = Waybill.find(params[:id])
    if waybill.apply
      render json: { result: 'success', id: waybill.id }
    else
      render json: waybill.errors.full_messages
    end
  end

  def cancel
    waybill = Waybill.find(params[:id])
    if waybill.cancel
      render json: { result: 'success', id: waybill.id }
    else
      render json: waybill.errors.full_messages
    end
  end
end
