# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Helpers
  module StateChange
    extend ActiveSupport::Concern

    module ClassMethods
      def act_as_statable(model)
        @model = model
      end

      attr_reader :model
    end

    def apply
      obj = self.class.model.find(params[:id])
      if obj.apply
        render json: { result: 'success', id: obj.id }
      else
        render json: obj.errors.full_messages
      end
    end

    def cancel
      obj = self.class.model.find(params[:id])
      if obj.cancel
        render json: { result: 'success', id: obj.id }
      else
        render json: obj.errors.full_messages
      end
    end

    def reverse
      obj = self.class.model.find(params[:id])
      if obj.reverse
        render json: { result: 'success', id: obj.id }
      else
        render json: obj.errors.full_messages
      end
    end
  end
end
