# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class StorekeepersController < ApplicationController
  def index
    @credentials = Credential.where(document_type: params[:document_type]).
        joins(:entity).where("entities.tag LIKE '%#{params[:term]}%'").
            order("entities.tag").limit(5)
  end
end
