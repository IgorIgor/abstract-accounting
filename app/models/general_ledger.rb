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
    def all(attrs = {})
      scope = Txn
      unless attrs[:page].nil?
        per_page = (!attrs[:per_page].nil? and attrs[:per_page].to_i) ||
            Settings.root.per_page.to_i
        scope = scope.limit(per_page).offset((attrs[:page].to_i - 1) * per_page)
        attrs.delete(:page)
        attrs.delete(:per_page)
      end
      scope.all(attrs)
    end

    def count
      Txn.count
    end
  end
end
