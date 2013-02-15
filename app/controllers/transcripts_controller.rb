# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class TranscriptsController < ApplicationController
  def index
    render 'index', layout: false
  end

  def data
    @transcript = nil
    @transcripts = []
    unless params[:deal_id].nil? || params[:date_from].nil? ||
        params[:date_to].nil?
      @transcript = Transcript.new(Deal.find(params[:deal_id]),
                                   DateTime.parse(params[:date_from]),
                                   DateTime.parse(params[:date_to]))
      @transcripts = @transcript.all({per_page: params[:per_page], page: params[:page] || 1, order: params[:order] || nil}).
                                includes(fact: [:from, :to])
    end
  end
end
