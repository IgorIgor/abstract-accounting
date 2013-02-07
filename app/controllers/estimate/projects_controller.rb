# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class ProjectsController < ApplicationController
    def index
      render 'index', layout: false
    end

    def preview
      render 'preview', layout: false
    end

    def new
      @project = Project.new
    end

    def show
      @project = Project.find params[:id]
    end

    def data
      page = params[:page].nil? ? 1 : params[:page].to_i
      per_page = params[:per_page].nil? ?
          Settings.root.per_page.to_i : params[:per_page].to_i
      filter = { paginate: { page: page, per_page: per_page }}
      filter[:sort] = params[:order] if params[:order]
      @projects = Project.filtrate(filter)
      @count = Project.count
    end

    def create
      Project.transaction do
        project_params = Project.build_params params
        project = Project.new(project_params)
        if project.save
          render json: { result: 'success', id: project.id }
        else
          render json: project.errors.full_messages
        end
      end
    end

    def update
      project = Project.find params[:id]
      Project.transaction do
        project_params = Project.build_params params
        if project.update_attributes(project_params)
          render json: { result: 'success', id: project.id }
        else
          render json: project.errors.full_messages
        end
      end
    end
  end
end
