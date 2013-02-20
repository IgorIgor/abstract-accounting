# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

class TestCommentableWithAutoComment < ActiveRecord::Base
  has_no_table
  column :id, :integer

  def id_changed?
    true
  end

  def new_record?
    false
  end

  def save
    run_callbacks :save
  end

  include Helpers::Commentable
  has_comments :auto_comment
end

class TestCommentable < ActiveRecord::Base
  has_no_table
  column :id, :integer

  def save
    run_callbacks :save
  end

  include Helpers::Commentable
  has_comments
end

describe Helpers::Commentable do
  subject { TestCommentable.new }

  it { subject.class.should include(Helpers::Commentable) }
  it { should have_many :comments }

  describe "#add_comment" do
    let(:obj) { subject }

    before :each do
      PaperTrail.enabled = true
    end

    it "should return false if record is new" do
      obj.stub(:new_record?).and_return(true)
      obj.add_comment("some message").should eq(false)
    end

    it 'should add comment on create and update' do
      PaperTrail.whodunnit = create :user
      expect { TestCommentableWithAutoComment.new().save.should be_true }.
          to change(Comment, :count).by(1)
      Comment.last.message.should eq I18n.t("activerecord.attributes.#{
        TestCommentableWithAutoComment.name.downcase.split('::').join('.')}.comment.create")
      expect { TestCommentable.new().save.should be_true }.to change(Comment, :count).by(0)
    end

    context "with not a new record" do
      let(:old_obj) { obj.stub(:new_record?).and_return(false); obj }

      it "shouldn't create comment if paper_trail disabled" do
        PaperTrail.enabled = false
        expect { old_obj.add_comment("some message").should eq(true) }.
            to change(Comment, :count).by(0)
      end

      it "shouldn't create comment if paper_trail whodunnit is nil" do
        PaperTrail.whodunnit = nil
        expect { old_obj.add_comment("some message").should eq(true) }.
            to change(Comment, :count).by(0)
      end

      it "shouldn't create comment if paper_trail whodunnit is root" do
        PaperTrail.whodunnit = RootUser.new
        expect { old_obj.add_comment("some message").should eq(true) }.
            to change(Comment, :count).by(0)
      end

      it "should create user" do
        PaperTrail.whodunnit = create(:user)
        old_obj.stub("[]").and_return(1)
        old_obj.stub(:id).and_return(1)
        old_obj.stub(:destroyed?).and_return(false)
        expect { old_obj.add_comment("some message").should eq(true) }.
            to change(Comment, :count).by(1)
        comment = Comment.first
        comment.user_id.should eq(PaperTrail.whodunnit.id)
        comment.item_id.should eq(old_obj.id)
        comment.item_type.should eq(TestCommentable.base_class.name)
        comment.message.should eq("some message")
      end
    end
  end
end
