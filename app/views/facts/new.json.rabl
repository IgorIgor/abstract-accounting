# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@fact => :fact) do
  attributes :day, :amount, :from_deal_id, :to_deal_id
end
child(Deal.new => :from) do
  attributes :tag
end
child(Deal.new => :to) do
  attributes :tag
end
