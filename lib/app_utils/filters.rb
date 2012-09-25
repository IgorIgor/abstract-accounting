# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "active_support/concern"

module AppUtils
  module ARFilters
    extend ActiveSupport::Concern

    module ClassMethods
      def custom_sort(name, &block)
        define_singleton_method "sort_by_#{name}".to_sym, &block
      end

      def filtrate(args)
        scope = scoped
        args.each { |key, value| scope = scope.send(key, value) }
        scope
      end

      def sort(*args)
        if args.count == 1
          args = [(args.first[:field] or args.first["field"]),
                  (args.first[:type] or args.first["type"])]
        end
        name, direction = *args
        if self.attribute_names.include?(name)
          scoped.order("#{name} #{direction}")
        elsif self.respond_to?("sort_by_#{name}".to_sym)
          scoped.send("sort_by_#{name}".to_sym, direction)
        else
          scoped
        end
      end

      def paginate(*args)
        if args.count == 1
          args = [(args.first[:page] or args.first["page"]),
                  (args.first[:per_page] or args.first["per_page"])]
        end
        page, per_page = *args
        scoped.limit(per_page).offset((page - 1) * per_page)
      end
    end
  end
end

ActiveRecord::Base.send(:include, AppUtils::ARFilters)
