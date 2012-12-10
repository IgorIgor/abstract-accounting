# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe User do
  it "should have next behaviour" do
    create(:user)
    should validate_presence_of :email
    should validate_presence_of :entity_id
    should validate_uniqueness_of(:email).scoped_to(:entity_id)
    should validate_format_of(:email).not_with("test@test")
    should ensure_length_of(:password).is_at_least(6)
    should allow_mass_assignment_of(:email)
    should allow_mass_assignment_of(:password)
    should allow_mass_assignment_of(:password_confirmation)
    should allow_mass_assignment_of(:entity)
    should_not allow_mass_assignment_of(:crypted_password)
    should_not allow_mass_assignment_of(:salt)
    should belong_to(:entity)
    should have_many User.versions_association_name
    User.new.root?.should be_false
    should have_many(:credentials)
    should have_and_belong_to_many(:groups)
    should have_one(:managed_group).class_name(Group)
  end

  it "should authenticate from config" do
    config = YAML::load(File.open("#{Rails.root}/config/application.yml"))
    user = User.authenticate("root@localhost",
                             config["defaults"]["root"]["password"])
    user.should_not be_nil
    user.root?.should be_true
  end

  it "should remember user" do
    user = create(:user)
    expect { user.remember_me! }.to change{user.remember_me_token}.from(nil)
    user = create(:user)
    expect { user.remember_me! }.to change{user.remember_me_token_expires_at}.from(nil)
  end

  it "should change password" do
    user = create(:user)
    new_user = User.load_from_reset_password_token(user.reset_password_token)
    new_user.should eq(user)
    new_user.change_password!("changed")
    new_user.crypted_password.should_not eq(user.crypted_password)
  end

  it "should return documents accessible by user" do
    user = create(:user)
    create(:credential, user: user, document_type: Document.documents[0])
    create(:credential, user: user, document_type: Document.documents[1])
    user.documents.should =~ user.credentials(:force_update).collect{ |c| c.document_type }
  end

  it "should return all user managers" do
    user = create(:user)
    user2 = create(:user)
    m1 = create(:user)
    m2 = create(:user)
    m3 = create(:user)
    m4 = create(:user)
    gr1 = create(:group, manager: m1)
    gr1.users<<[user, user2, m4]
    gr2 = create(:group, manager: m2)
    gr2.users<<[m1, m3]
    gr3 = create(:group, manager: m3)
    gr3.users<<[m2, user2, m4]
    gr4 = create(:group, manager: m4)
    gr4.users<<[user, m1, user2]

    managers = user.managers

    managers.include?(m1).should be_true
    managers.include?(m2).should be_true
    managers.include?(m3).should be_true
    managers.include?(m4).should be_true
    managers.include?(user).should_not be_true
    managers.include?(user2).should_not be_true
  end
end
