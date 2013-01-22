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
    def index
      if params[:term]
        @boms = BoM.where{lower(uid).like lower("%#{my{params[:term]}}%")}.
            order('uid').limit(5)
        render :autocomplete
      end
    end

    def preview
      render 'estimate/bo_ms/preview', layout: false
    end

    def new
      @bo_m = BoM.new
    end

    def show
      @bo_m = BoM.find params[:id]
    end

    def create
      if params[:elements]
        BoM.transaction do
          if params[:bo_m][:resource_id]
            resource_id = params[:bo_m][:resource_id]
          else
            if Asset.find_by_tag_and_mu(params[:resource][:tag], params[:resource][:mu])
              asset = Asset.find_by_tag_and_mu(params[:resource][:tag], params[:resource][:mu])
            else
              asset = Asset.create(tag: params[:resource][:tag], mu: params[:resource][:mu])
            end
            resource_id = asset.id
          end
          bom = BoM.new(uid: params[:bo_m][:uid], resource_id: resource_id)
          bom.element_builders(params[:elements][:builders][:rate],
                               params[:elements][:rank][:rate]) if params[:elements][:builders]
          bom.element_machinist(params[:elements][:machinist][:rate]) if params[:elements][:machinist]
          if params[:elements][:machinery]
            params[:elements][:machinery].each { |item| bom.element_items(item[1], BoM::MACHINERY)}
          end
          if params[:elements][:resources]
            params[:elements][:resources].each { |item| bom.element_items(item[1], BoM::RESOURCES)}
          end
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

    def update
      if params[:elements]
        bom = BoM.find params[:id]
        BoM.transaction do
          if params[:bo_m][:resource_id]
            resource_id = params[:bo_m][:resource_id]
          else
            if Asset.find_by_tag_and_mu(params[:resource][:tag], params[:resource][:mu])
              asset = Asset.find_by_tag_and_mu(params[:resource][:tag], params[:resource][:mu])
            else
              asset = Asset.create(tag: params[:resource][:tag], mu: params[:resource][:mu])
            end
            resource_id = asset.id
          end
          bom.items.delete_all
          bom.element_builders(params[:elements][:builders][:rate],
                               params[:elements][:rank][:rate]) if params[:elements][:builders]
          bom.element_machinist(params[:elements][:machinist][:rate]) if params[:elements][:machinist]
          if params[:elements][:machinery]
            params[:elements][:machinery].each { |item| bom.element_items(item[1], BoM::MACHINERY)}
          end
          if params[:elements][:resources]
            params[:elements][:resources].each { |item| bom.element_items(item[1], BoM::RESOURCES)}
          end
          if bom.update_attributes(uid: params[:bo_m][:uid], resource_id: resource_id)
            bom.machinist
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
