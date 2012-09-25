# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

node(:state) do |obj|
  case obj.state
  when ::Helpers::Statable::UNKNOWN
    I18n.t 'views.statable.unknown'
  when ::Helpers::Statable::INWORK
    I18n.t 'views.statable.inwork'
  when ::Helpers::Statable::CANCELED
    I18n.t 'views.statable.canceled'
  when ::Helpers::Statable::APPLIED
    I18n.t 'views.statable.applied'
  when ::Helpers::Statable::REVERSED
    I18n.t 'views.statable.reversed'
  end
end
