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

    module FilterMethods
      def filtrate(args)
        scope = scoped
        args.each { |key, value| scope = scope.send(key, value) }
        scope
      end

      def sort(*args)
        ap "sort in filters"
        ap args
        if args.count == 1
          args = [(args.first[:field] or args.first["field"]),
                  (args.first[:type] or args.first["type"])]
        end
        name, direction = *args
        if self.attribute_names.include?(name)
          ap "simple order"
          scoped.order("#{name} #{direction}")
        elsif self.respond_to?("sort_by_#{name}".to_sym)
          ap "order by name"
          scoped.send("sort_by_#{name}".to_sym, direction)
        else
          scoped
        end
      end

      def search(*args)
        scope = scoped
        args.first.each do |key, value|
          if self.attribute_names.include?(key) || self.attribute_names.include?(key.to_s)
            scope = scope.where{lower(__send__(key)).like(lower("%#{value}%"))}
          elsif self.respond_to?("search_by_#{key}".to_sym)
            scope = scope.send("search_by_#{key}".to_sym, value)
          end
        end
        scope
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

    module ClassMethods
      def custom_sort(name, &block)
        define_singleton_method "sort_by_#{name}".to_sym, &block
      end

      def custom_search(name, &block)
        define_singleton_method "search_by_#{name}".to_sym, &block
      end

      include FilterMethods
    end
  end
end

ActiveRecord::Base.send(:include, AppUtils::ARFilters)
