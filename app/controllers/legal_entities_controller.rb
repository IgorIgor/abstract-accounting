# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class LegalEntitiesController < ApplicationController
  def index
    if params[:term]
      @entities = LegalEntity.search(name: params[:term]).order("name").limit(5)
    else
      render 'index', layout: false
    end
  end

  def preview
    render 'preview', layout: false
  end

  def new
    @legal_entity = LegalEntity.new
  end

  def show
    @legal_entity = LegalEntity.find(params[:id])
  end

  def list
    filter = {}
    filter[:search] = params[:like]  if params[:like]
    @entities = LegalEntity.filtrate(filter)
    @count = @entities.count
    filter = generate_paginate
    filter[:sort] = params[:order] if params[:order]
    @entities = @entities.filtrate(filter)
  end

  def create
    legal_entity = nil
    begin
      LegalEntity.transaction do
        country = Country.find_or_create_by_tag(params[:country][:tag])
        params[:legal_entity][:country_id] = country.id
        legal_entity = LegalEntity.create!(params[:legal_entity])
        render json: { result: 'success', id: legal_entity.id }
      end
    rescue
      render json: legal_entity.errors.full_messages
    end
  end

  def update
    legal_entity = LegalEntity.find(params[:id])
    begin
      LegalEntity.transaction do
        unless legal_entity.country.tag == params[:country][:tag]
          country = Country.find_or_create_by_tag(params[:country][:tag])
          legal_entity.country = country
          params[:legal_entity][:country_id] = country.id
        end
        legal_entity.update_attributes(params[:legal_entity])
        render json: { result: 'success', id: legal_entity.id }
      end
    rescue
      render json: legal_entity.errors.full_messages
    end
  end
end
