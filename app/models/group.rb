# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class ManagerValidator < ActiveModel::Validator
  def validate(record)
    if  record.user_ids.include? record.manager_id
      record.errors[:manager] << I18n.t(
          "activerecord.errors.models.group.manager_in_users")
    end
  end
end

class Group < ActiveRecord::Base
  has_paper_trail
  validates_presence_of :manager_id, :tag
  validates_uniqueness_of :tag
  validates_with ManagerValidator
  belongs_to :manager, :class_name => 'User'
  has_and_belongs_to_many :users, before_add: :evaluate_user

  def evaluate_user(user)
    if user.id == manager_id
      errors[:users] << I18n.t(
          "activerecord.errors.models.group.users_same_as_manager")
      raise 'wrong user. same as manager'
    end
    if users.where("id=#{user.id}").any?
      errors[:users] << I18n.t("activerecord.errors.models.group.users_unique")
      raise 'wrong user. not unique'
    end
  end
end
