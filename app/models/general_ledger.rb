# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GeneralLedger
  class << self
    def on_date(date = nil)
      date = date.nil? ? Date.current : Date.parse(date)
      self.current_scope = self.current_scope.on_date(date)
      self
    end

    def paginate(attrs = {})
      unless attrs[:page].nil?
        per_page = (!attrs[:per_page].nil? and attrs[:per_page].to_i) ||
            Settings.root.per_page.to_i
        self.current_scope = self.current_scope.limit(per_page).
                                      offset((attrs[:page].to_i - 1) * per_page)
      end
      self
    end

    def all(attrs = {})
      scope = self.current_scope
      self.current_scope = Txn
      scope.all(attrs)
    end

    def count
      scope = self.current_scope
      self.current_scope = Txn
      scope.count
    end

    protected
    def current_scope
      Thread.current["#{self}_current_scope"] or Txn
    end

    def current_scope=(scope)
      Thread.current["#{self}_current_scope"] = scope
    end
  end
end
