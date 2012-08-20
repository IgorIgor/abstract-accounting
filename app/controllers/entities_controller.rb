# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class EntitiesController < ApplicationController
  def index
    if params[:term]
      term = params[:term]
      @entities = Entity.where{tag =~ "%#{term}%"}.order("tag").limit(5)
    else
      render 'index', layout: params[:selection] ? 'form_selection' : false
    end
  end

  def preview
    render 'entities/preview', layout: false
  end

  def new
    @entity = Entity.new
  end

  def show
    @entity = Entity.find(params[:id])
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i

    @entities = SubjectOfLaw.all(page: page, per_page: per_page)
    @count = SubjectOfLaw.count
  end

  def autocomplete
    @entities = SubjectOfLaw.where({tag: {like: params[:term]}}).limit(5).order_by('tag').all
  end

  def create
    entity = nil
    begin
      Entity.transaction do
        entity = Entity.create(params[:entity])
        render json: { result: 'success', id: entity.id }
      end
    rescue
      render json: entity.errors.full_messages
    end
  end

  def update
    entity = Entity.find(params[:id])
    begin
      Entity.transaction do
        entity.update_attributes(params[:entity])
        render json: { result: 'success', id: entity.id }
      end
    rescue
      render json: entity.errors.full_messages
    end
  end
end
