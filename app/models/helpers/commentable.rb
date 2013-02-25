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
      def has_comments(auto_comment = false)
        has_many :comments, :as => :item
        after_save :after_save if auto_comment
      end
    end

    def after_save
      name = self.class.name.downcase.split('::').join('.')
      if self.id_changed?
        add_comment(I18n.t("activerecord.attributes.#{name}.comment.create"))
      else
        add_comment(I18n.t("activerecord.attributes.#{name}.comment.update"))
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
