# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

describe Notifiers::MailerNotifier do
  describe "should have next behavior" do
    it "send mail to all recipients when warning" do
      user = create(:user)
      m1 = create(:user)
      m2 = create(:user)
      m3 = create(:user)

      create(:group, manager: m1).users<<[user, m2]
      create(:group, manager: m2).users<<[m3, m1]
      create(:group, manager: m3).users<<m2
      PaperTrail.enabled = true
      PaperTrail.whodunnit = user

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
      create(:fact,
             :from => deal1, :to => deal2,
             :resource => deal1.take.resource,
             :amount => 50.0,)

      mail = ActionMailer::Base.deliveries.last
      mail.to.should eq([user.email, m1.email, m2.email, m3.email])
      PaperTrail.enabled = false
    end

    it "should not send mail if version is not specified" do
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
      expect do
        create(:fact,
               :from => deal1, :to => deal2,
               :resource => deal1.take.resource,
               :amount => 50.0,)
      end.to_not change(ActionMailer::Base.deliveries, :count)
    end

    it "should not send mail if object created by root user" do
      PaperTrail.enabled = true
      PaperTrail.whodunnit = RootUser.new

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

      expect do
        create(:fact,
               :from => deal1, :to => deal2,
               :resource => deal1.take.resource,
               :amount => 50.0,)
      end.to_not change(ActionMailer::Base.deliveries, :count)
      PaperTrail.enabled = false
    end
  end
end
