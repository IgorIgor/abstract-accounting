# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe NotifiedUser do
  it { should belong_to :user }
  it { should belong_to :notification }

  it { should allow_mass_assignment_of :notification_id }
  it { should allow_mass_assignment_of :user_id }
  it { should allow_mass_assignment_of :looked }
end

