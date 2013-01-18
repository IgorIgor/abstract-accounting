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

      scope = Catalog.with_parent_id(params[:parent_id])
      scope = scope.search(params[:like]) if params[:like]
      @count = scope.count
      filter = { paginate: { page: page, per_page: per_page }}
      filter[:sort] = params[:order] if params[:order]
      @catalogs = scope.filtrate(filter).order{id.asc}
    end

    def new
      @catalog = Catalog.new(parent_id: params[:parent_id])
      @catalog.build_parent unless @catalog.parent(:reload)
    end

    def create
      catalog = Catalog.new(catalog_params)
      catalog.build_document(params[:document]) if params[:document]
      if catalog.save
        render json: { result: 'success', id: catalog.id }
      else
        render json: catalog.errors.full_messages
      end
    end

    def update
      catalog = Catalog.find(params[:id])
      Catalog.transaction do
        success = catalog.update_attributes(catalog_params)
        success = catalog.create_or_update_document(params[:document]) if params[:document]
        if success && catalog.save
          render json: { result: 'success', id: catalog.id }
        else
          render json: catalog.errors.full_messages
        end
      end
    end

    def show
      @catalog = Catalog.find(params[:id])
      @have_document = !!@catalog.document
      @catalog.build_document unless @have_document
      @catalog.build_parent unless @catalog.parent(:reload)
    end

    def document
      @document = Catalog.find(params[:id]).document
      render text: @document.data, layout: false
    end

    private
      def catalog_params
        params[:catalog].delete(:parent_tag)
        params[:catalog]
      end
  end
end
