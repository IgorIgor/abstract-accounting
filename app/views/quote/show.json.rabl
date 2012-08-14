# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @quote.id }
child(@quote => :quote) do
  attributes :rate, :money_id
  node(:day) { |quote| quote.day.strftime("%m/%d/%Y") }
end
child(@quote.money => :money) do
  attributes :alpha_code
end
