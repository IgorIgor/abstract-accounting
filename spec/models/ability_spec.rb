# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'
require "cancan/matchers"

describe Ability do
  it "should have next behaviour" do
    user = create(:user)
    Ability.new(user).should_not be_able_to(:manage, :all)
    Ability.new(nil).should_not be_able_to(:manage, :all)
    Ability.new(RootUser.new).should be_able_to(:manage, :all)

    subordinate1 = create(:user)
    create(:credential, user: subordinate1, document_type: Entity.name)

    Ability.new(subordinate1).should be_able_to(:manage, Entity)

    subordinate2 = create(:user)
    create(:credential, user: subordinate2, document_type: Asset.name)

    Ability.new(subordinate2).should be_able_to(:manage, Asset)

    boss = create(:user)
    group = create(:group, manager: boss)
    group.user_ids = [subordinate1.id, subordinate2.id]

    Ability.new(boss).should be_able_to(:manage, Entity)
    Ability.new(boss).should be_able_to(:manage, Asset)

    create(:credential, user: boss, document_type: Money.name)

    Ability.new(boss).should be_able_to(:manage, Money)
  end
end
