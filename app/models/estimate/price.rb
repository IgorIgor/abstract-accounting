# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Price < Base
    validates_presence_of :date, :bo_m_id, :direct_cost, :catalog_id
    validates_uniqueness_of :date, :scope => [:bo_m_id, :catalog_id]

    belongs_to :bo_m, class_name: BoM
    belongs_to :catalog

    delegate :uid, :tag, :mu, to: :bo_m, allow_nil: true
    delegate :resource, to: :bo_m, allow_nil: true

    class << self
      def with_catalog_id(cid)
        where{catalog_id == my{cid}}
      end

      def with_bo_m_id(bid)
        where{bo_m_id == bid}
      end

      def with_date_less_or_eq_to(arg_date)
        where{date <= my{arg_date}}
      end

      def with_uid(uid)
        joins{bo_m}.where{bo_m.uid == uid}
      end

      def with_catalog_pid(cpid)
        children = Catalog.find(cpid).children
        where{catalog_id.in(children)}
      end
    end

    custom_sort(:uid) do |dir|
      joins{bo_m}.order{bo_m.uid.__send__(dir)}
    end

    custom_sort(:tag) do |dir|
      joins{bo_m.resource}.order{bo_m.resource.tag.__send__(dir)}
    end

    custom_sort(:mu) do |dir|
      joins{bo_m.resource}.order{bo_m.resource.mu.__send__(dir)}
    end

    custom_sort(:catalog_tag) do |dir|
      joins{catalog}.order{catalog.tag.__send__(dir)}
    end
  end
end
