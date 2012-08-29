# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Commentable
  def send_comment(object, message)
    unless PaperTrail.whodunnit.nil? || PaperTrail.whodunnit.root?
      attrs = {}
      attrs[:user_id] = PaperTrail.whodunnit.id
      attrs[:item_id] = object.id
      attrs[:item_type] = object.class.name
      attrs[:message] = message
      return !Comment.create(attrs).nil?
    end
    true
  end
end
