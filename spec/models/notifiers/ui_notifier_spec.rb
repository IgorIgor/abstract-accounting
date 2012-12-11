# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

describe Notifiers::UINotifier do
  it "should create notification to all recipients when warning" do
    user = create :user
    m1 = create :user
    m2 = create :user
    m3 = create :user

    create(:group, manager: m1).users<<[user, m2]
    create(:group, manager: m2).users<<[m3, m1]
    create(:group, manager: m3).users<<m2
    PaperTrail.enabled = true
    PaperTrail.whodunnit = user

    rub = create :money
    aasii = create :asset
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    create(:fact,
           :from => deal1, :to => deal2,
           :resource => deal1.take.resource,
           :amount => 50.0,)

    notification = Notification.last
    users = NotifiedUser.where{notification_id == notification.id}.pluck(:user_id)
    users.should eq([user.id, m1.id, m2.id, m3.id])
    PaperTrail.enabled = false
  end

  it "should not create notification if version is not specified" do
    rub = create :money
    aasii = create :asset
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    expect do
      create(:fact,
             :from => deal1, :to => deal2,
             :resource => deal1.take.resource,
             :amount => 50.0,)
    end.to_not change(Notification, :count) &&
               change(NotifiedUser, :count)
  end

  it "should not create notification if object created by root user" do
    PaperTrail.enabled = true
    PaperTrail.whodunnit = RootUser.new

    rub = create :money
    aasii = create :asset
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)

    expect do
      create(:fact,
             :from => deal1, :to => deal2,
             :resource => deal1.take.resource,
             :amount => 50.0,)
    end.to_not change(Notification, :count) &&
               change(NotifiedUser, :count)
    PaperTrail.enabled = false
  end

  it "show notification limit_amount to user and his managers" do
    user = create :user
    m1 = create :user
    m2 = create :user
    m3 = create :user

    PaperTrail.enabled = true
    PaperTrail.whodunnit = user

    rub = create :money
    aasii = create :asset
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :limit => Limit.new(side: Limit::ACTIVE, amount: 0),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    fact = create(:fact,
                  :from => deal1, :to => deal2,
                  :resource => deal1.take.resource,
                  :amount => 50.0)
    warning = Warnings::LimitAmount.new(deal1, fact)

    create(:group, manager: m1).users<<[user, m2]
    create(:group, manager: m2).users<<[m3, m1]
    create(:group, manager: m3).users<<m2

    expect {Notifiers::UINotifier.new.update(warning)}.to change(Notification, :count).by(1) &&
                                                      change(NotifiedUser, :count).by(4)
    notification = Notification.first
    users = NotifiedUser.where{notification_id == notification.id}.pluck(:user_id)
    users.should =~ [user.id, m1.id, m2.id, m3.id]
    notification.title.should match(I18n.t('warnings.limit.amount.title', user: user.entity.tag))
    notification.message.should match(I18n.t('warnings.limit.amount.message',
                                          warning_object_id: warning.object.id))
    notification.notification_type.should eq(Notification::WARNING)
    notification.date.to_date.should eq(Date.today)
  end

  it "show notification dial_priority to user and his managers", focus: true do
    user = create :user
    m1 = create :user
    m2 = create :user
    m3 = create :user

    PaperTrail.enabled = true
    PaperTrail.whodunnit = user

    rub = create :money
    aasii = create :asset
    deal1 = create(:deal,
                   :give => build(:deal_give, :resource => aasii),
                   :take => build(:deal_take, :resource => rub),
                   :limit => Limit.new(side: Limit::ACTIVE, amount: 0),
                   :rate => 10000.0)
    deal2 = create(:deal,
                   :take => build(:deal_give, :resource => aasii),
                   :give => build(:deal_take, :resource => rub),
                   :rate => 10000.0)
    fact = create(:fact,
                  :from => deal1, :to => deal2,
                  :resource => deal1.take.resource,
                  :amount => 50.0)
    warning = Warnings::DealPriority.new(deal1, fact.from, fact.to)

    create(:group, manager: m1).users<<[user, m2]
    create(:group, manager: m2).users<<[m3, m1]
    create(:group, manager: m3).users<<m2

    expect {Notifiers::UINotifier.new.update(warning)}.to change(Notification, :count).by(1) &&
                                                              change(NotifiedUser, :count).by(4)
    notification = Notification.first
    users = NotifiedUser.where{notification_id == notification.id}.pluck(:user_id)
    users.should =~ [user.id, m1.id, m2.id, m3.id]
    notification.title.should match(I18n.t('warnings.deal.priority.title', user: user.entity.tag))
    notification.message.should eq(I18n.t('warnings.deal.priority.message',
                                             warning_object_id: warning.object.id,
                                             warning_object_tag: warning.object.tag,
                                             expected_id: warning.expected.id,
                                             expected_tag: warning.expected.tag,
                                             got_id: warning.got.id,
                                             got_tag: warning.got.tag))
    notification.notification_type.should eq(Notification::WARNING)
    notification.date.to_date.should eq(Date.today)
  end
end
