# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Notification do
  it { should have_many :notified_users }

  it { should allow_mass_assignment_of :date }
  it { should allow_mass_assignment_of :message }
  it { should allow_mass_assignment_of :title }
  it { should allow_mass_assignment_of :notification_type }

  it 'should assign users' do
    3.times { create :user }
    notify = Notification.create(title: 'new', message: 'msg',
                                 notification_type: 1, date: DateTime.now)
    expect { notify.assign_users }.to change(NotifiedUser, :count).by 3
    NotifiedUser.first.user_id.should eq(User.first.id)
    NotifiedUser.first.notification_id.should eq(notify.id)
    NotifiedUser.first.looked.should be_false
    NotifiedUser.last.user_id.should eq(User.last.id)
    NotifiedUser.last.notification_id.should eq(notify.id)
    NotifiedUser.last.looked.should be_false
  end
end
