# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

describe NotificationMailer do
  describe "user_notification_email" do
    before(:all) do
      @user = create(:user)
      PaperTrail.enabled = true
      PaperTrail.whodunnit = @user

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
      fact = create(:fact,
                    :from => deal1, :to => deal2,
                    :resource => deal1.take.resource,
                    :amount => 50.0,)
      @warning = Warnings::LimitAmount.new(deal1, fact)
    end

    it "send notification email to user and his managers" do
      m1 = create(:user)
      m2 = create(:user)
      m3 = create(:user)

      create(:group, manager: m1).users<<[@user, m2]
      create(:group, manager: m2).users<<[m3, m1]
      create(:group, manager: m3).users<<m2

      mail = NotificationMailer.notification_email([@user.email, m1.email, m2.email, m3.email], @warning).deliver

      mail.subject.should eq(I18n.t("warnings.warning") + '!')
      mail.to.should eq([@user.email, m1.email, m2.email, m3.email])
      mail.from.should eq(["admin@aasii.org"])
      mail.body.encoded.should match(I18n.t('warnings.limit.amount.title') + ": #{@user.entity.tag}")
      mail.body.encoded.should match(I18n.t('warnings.limit.amount.message',
                                            warning_object_id: @warning.object.id))
    end
  end
end
