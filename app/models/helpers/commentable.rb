# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Helpers
  module Commentable
    extend ActiveSupport::Concern

    module ClassMethods
      def has_comments
        has_many :comments, :as => :item
      end
    end

    def add_comment(message)
      return false if self.new_record?
      return true unless PaperTrail.enabled?
      return true unless PaperTrail.whodunnit
      return true if PaperTrail.whodunnit.root?
      !!Comment.create(user_id: PaperTrail.whodunnit.id, message: message, item: self)
    end
  end
end
