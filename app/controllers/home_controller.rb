# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class HomeController < ApplicationController
  skip_before_filter :check_chart, only: [:index]

  def user_documents
    if current_user.root?
      Document.documents
    else
      current_user.documents & Document.documents
    end
  end

  def index
    @types = user_documents
  end

  def inbox
    respond_to do |format|
      format.html { render "home/documents", :layout => false }
      format.json do
        @documents = []
        @count = 0
        if current_user.root? || (!current_user.root? && !current_user.managed_documents.empty?)
          scoped_versions = Document.lasts.by_user(current_user).filter(params[:like])
          @documents = scoped_versions.paginate(page: params[:page],
                                                per_page: params[:per_page]).all
          @count = scoped_versions.count
        end
        render "home/data"
      end
    end
  end

  def archive
    respond_to do |format|
      format.html { render "home/documents", :layout => false }
      format.json do
        @documents = []
        @count = 0
        unless user_documents.empty?
          scoped_versions = Document.lasts.by_user(current_user).filter(params[:like])
          @documents = scoped_versions.paginate(page: params[:page], per_page: params[:per_page]).
              all()#include: [item: [:versions, :storekeeper]])
          @count = scoped_versions.count
        end
        render "home/data"
      end
    end
  end
end
