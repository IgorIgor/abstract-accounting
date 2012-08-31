# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Converter
  def self.float(value)
    value.instance_of?(Float) ? value : value.to_f
  end

  def self.int(value)
    value.instance_of?(Integer) ? value : value.to_i
  end
end
