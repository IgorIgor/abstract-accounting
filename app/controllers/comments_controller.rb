# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class CommentsController < ApplicationController
  def index
    @comments = Comment.find_all_by_item_id_and_item_type(params[:item_id],
                                                          params[:item_type])
  end

  def create
    params[:comment][:user] = current_user
    Comment.create!(params[:comment])
    render text: 'success'
  end
end
