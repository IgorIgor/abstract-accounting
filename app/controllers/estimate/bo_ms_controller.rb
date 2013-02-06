# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class BoMsController < ApplicationController
    def preview
      render 'preview', layout: false
    end

    def new
      @bo_m = BoM.new
    end

    def show
      @bo_m = BoM.find params[:id]
    end

    def create
      save do
        BoM.new(params[:bo_m])
      end
    end

    def update
      save do
        bom = BoM.find params[:id]
        bom.items.delete_all
        bom.assign_attributes(params[:bo_m])
        bom
      end
    end

    private
      def save
        if params[:materials] || params[:materials] ||
            params[:bo_m][:workers_amount] || params[:bo_m][:drivers_amount]
          BoM.transaction do
            params[:bo_m][:resource_id] ||= BoM.create_resource(params[:resource]).id
            bom = yield
            params[:materials].values.each { |item| bom.build_materials(item) } if params[:materials]
            params[:machinery].values.each { |item| bom.build_machinery(item) } if params[:machinery]
            if bom.save
              render json: { result: 'success', id: bom.id }
            else
              render json: bom.errors.full_messages
            end
          end
        else
          render json: ["#{I18n.t('views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}"]
        end
      end
  end
end
