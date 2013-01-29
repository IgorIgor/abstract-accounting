# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Catalog < Base
    validates :tag, :presence => true
    validates_uniqueness_of :tag, :scope => :parent_id
    belongs_to :parent, class_name: Catalog
    has_many :subcatalogs, class_name: Catalog, :foreign_key => :parent_id
    has_many :boms, class_name: BoM
    has_many :prices
    belongs_to :document

    def create_or_update_document(data)
      if document.nil?
        create_document(data)
      else
        document.update_attributes(data)
      end
    end

    class << self
      def with_parent_id(pid)
        where{parent_id == pid}
      end
    end

    def children(catalog = self)
      return if catalog.nil?
      array_of_children = [catalog]
      catalog.subcatalogs.each do |subcatalog|
        array_of_children = array_of_children.concat(children(subcatalog))
      end
      array_of_children
    end
  end
end
