# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

class TestNotificator
  attr_reader :warning_object
  def initialize
    @warning_object = nil
  end
  def update(warning_object)
    @warning_object = warning_object
  end
end

describe Observers::WarningObserver do
  before :all do
    @user = create(:user)
    PaperTrail.enabled = true
    PaperTrail.whodunnit = @user
  end

  it "should have next behaviour" do
    test_notificator = TestNotificator.new
    Observers::WarningObserver.instance.add_observer(test_notificator)

    rub= create(:money)
    aasii = create(:asset)
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    create(:fact, :from => deal1, :to => deal2, :resource => deal1.take.resource, :amount => 50.0,)

    test_notificator.warning_object.object.should eq(deal1)
    test_notificator.warning_object.expected.should eq(deal2)
    test_notificator.warning_object.got.should eq(deal1)
  end
end
