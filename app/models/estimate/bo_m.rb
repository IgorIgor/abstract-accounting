# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class BoM < Base
    BOM = 1
    MACHINERY = 2
    MATERIALS = 3

    validates_presence_of :resource_id, :uid, :bom_type
    validates_presence_of :catalog_id, if: Proc.new { |bom| bom.bom_type == BOM }
    validates_inclusion_of :bom_type, in: [BOM, MACHINERY, MATERIALS]

    belongs_to :resource, class_name: "::#{Asset.name}"
    belongs_to :catalog

    has_many :items, class_name: BoM, foreign_key: :parent_id
    has_many :machinery, class_name: BoM, foreign_key: :parent_id,
             conditions: { bom_type: MACHINERY }
    has_many :materials, class_name: BoM, foreign_key: :parent_id,
             conditions: { bom_type: MATERIALS }
    has_many :prices

    delegate :tag, :mu, to: :resource

    after_initialize :initialize_bom_type

    custom_sort(:tag) do |dir|
      joins{resource}.order{resource.tag.__send__(dir)}
    end

    custom_sort(:mu) do |dir|
      joins{resource}.order{resource.mu.__send__(dir)}
    end

    custom_sort(:catalog_tag) do |dir|
      joins{catalog}.order{catalog.tag.__send__(dir)}
    end

    class << self
      def create_resource(args)
        resource = Asset.with_lower_tag_eq_to(args[:tag]).with_lower_mu_eq_to(args[:mu]).first
        resource || Asset.create(args)
      end

      def with_catalog_id(cid)
        where{catalog_id == my{cid}}
      end

      def with_catalog_pid(cpid)
        children = Catalog.find(cpid).children
        where{catalog_id.in(children)}
      end

      def only_boms
        where{bom_type == BOM}
      end
    end

    def build_machinery(args)
      if args.has_key?(:resource) && args[:resource].kind_of?(Hash)
        args[:resource] = BoM.create_resource(args[:resource])
      end
      self.machinery.build(args)
    end

    def build_materials(args)
      if args.has_key?(:resource) && args[:resource].kind_of?(Hash)
        args[:resource] = BoM.create_resource(args[:resource])
      end
      self.materials.build(args)
    end

    custom_search(:mu) do |value|
      joins{resource}.where{lower(resource.mu).like(lower("%#{value}%"))}
    end

    custom_search(:tags) do |value|
      joins{resource}.where do
        scope = lower(resource.tag).like(lower("%#{my{value["main"]}}%"))
        if my{value["more"]}
          my{value["more"]}.each do |item|
            tmp_scope = lower(resource.tag).like(lower("%#{item[1][:tag]}%"))
            if item[1][:type] == I18n.t('views.estimates.filter.and')
              scope = scope ? scope & tmp_scope : tmp_scope
            else
              scope = scope ? scope | tmp_scope : tmp_scope
            end
          end
        end
        scope
      end
    end

    private
      def initialize_bom_type
        self.bom_type ||= BOM
      end
  end
end
