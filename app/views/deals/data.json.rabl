# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@deals => :objects) do
  attributes :id, :tag
  node(:entity_tag) { |deal| deal.entity.name }
  node(:give) do |deal|
    if deal.give.resource.instance_of?( Asset ) && deal.give.resource.mu
      "#{deal.give.resource.tag}, #{deal.give.resource.mu}"
    else
      deal.give.resource.tag
    end
  end
  node(:take) do |deal|
    if deal.take.resource.instance_of?( Asset ) && deal.take.resource.mu
      "#{deal.take.resource.tag}, #{deal.take.resource.mu}"
    else
      deal.take.resource.tag
    end
  end
  node(:rate) { |deal| deal.rate.to_s }
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
