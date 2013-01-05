# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class CatalogsController < ApplicationController
    def index
      render 'index', layout: false
    end

    def preview
      render 'preview', layout: false
    end

    def data
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i

      scope = Catalog.where{parent_id == my{params[:parent_id]}}
      @count = scope.count
      @catalogs = scope.order("id ASC").limit(per_page).offset((page - 1) * per_page)
    end

    def new
      @parent = Catalog.find(params[:parent_id]) if params[:parent_id]
      @catalog = Catalog.new
    end

    def create
      params[:catalog].delete(:parent_tag)
      catalog = Catalog.new(params[:catalog])
      if params[:document] && params[:document][:title] && params[:document][:data]
        catalog.build_document(params[:document])
      end
      if catalog.save
        render json: { result: 'success', id: catalog.id }
      else
        render json: catalog.errors.full_messages
      end
    end

    def update
      params[:catalog].delete(:parent_tag)
      catalog = Catalog.find(params[:id])
      begin
        Catalog.transaction do
          if params[:document] && params[:document][:title] && params[:document][:data]
            if catalog.document.nil?
              catalog.create_document!(params[:document])
            else
              if catalog.document.title != params[:document][:title] ||
                  catalog.document.data != params[:document][:data]
                catalog.document.update_attributes!(params[:document])
              end
            end
          end
          catalog.update_attributes!(params[:catalog])
          render json: { result: 'success', id: catalog.id }
        end
      rescue
        render json: catalog.errors.full_messages
      end
    end

    def show
      @catalog = Catalog.find(params[:id])

      @have_document = !@catalog.document.nil?
      @catalog.build_document unless @have_document
    end

    def document
      catalog = Catalog.find(params[:id])
      @document = catalog.document
      render text: @document.data, layout: false
    end
  end
end
