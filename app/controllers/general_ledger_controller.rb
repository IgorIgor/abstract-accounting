# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GeneralLedgerController < ApplicationController
  def index
    render 'index', layout: false
  end

  def data
    @gl = GeneralLedger.paginate(page: params[:page].nil? ? 1 : params[:page],
                                 per_page: params[:per_page]).
                        all(include: [fact: [:resource]])
    @count = GeneralLedger.count
  end
end
