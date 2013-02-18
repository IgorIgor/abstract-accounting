# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class Local < Base
    validates_presence_of :tag, :date, :project_id

    belongs_to :project
    delegate :boms_catalog, to: :project
    delegate :prices_catalog, to: :project

    has_many :items, class_name: LocalElement, foreign_key: :local_id

    include Helpers::Commentable
    has_comments

    class << self
      def by_project(pid)
        where{project_id == pid}
      end
    end
  end
end
