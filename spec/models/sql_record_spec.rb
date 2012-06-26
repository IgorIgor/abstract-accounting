# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "rspec"
require 'spec_helper'

describe SqlRecord do
  before :all do
    4.times { create(:asset) }
    4.times { create(:money) }
  end

  describe "#builder" do
    it "should define instance method" do
      str = "hello getter"
      SqlRecord.class_eval do
        builder :test do
          str
        end
      end
      SqlRecord.new.test.should eq(str)
    end

    it "should define singleton method" do
      str = "hello getter2"
      SqlRecord.class_eval do
        builder :test do
          str
        end
      end
      SqlRecord.test.should eq(str)
    end

    it "should pass arguments" do
      SqlRecord.class_eval do
        builder :test do |i|
          5 + i
        end
      end
      SqlRecord.test(9).should eq(14)
    end
  end

  describe "#union" do
    it "should create union" do
      sql = "#{Asset.select(:tag).to_sql} UNION #{Money.select("alpha_code as tag").to_sql}"
      SqlRecord.union(Asset.select(:tag).to_sql, Money.select("alpha_code as tag").to_sql).
          to_sql.should eq(sql)
    end
  end

  describe "#select" do
    it "should raise error on empty sql" do
      expect { SqlRecord.new.select("some") }.should raise_error
    end

    it "should return data array" do
      data = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       select("tag")
      data.count.should eq(Asset.count + Money.count)
    end

    it "should return data as collection of objects with methods" do
      data = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       select("tag")
      data.first.respond_to?(:tag).should be_true
      data.collect(&:tag).should =~ (Asset.all.collect(&:tag) +
                                     Money.all.collect(&:alpha_code))
    end
  end

  describe "#all" do
    it "should raise error on empty sql" do
      expect { SqlRecord.new.all }.should raise_error
    end

    it "should return data array" do
      data = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       all
      data.count.should eq(Asset.count + Money.count)
    end

    it "should return data as collection of objects with methods" do
      data = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       all
      data.first.respond_to?(:tag).should be_true
      data.collect(&:tag).should =~ (Asset.all.collect(&:tag) +
                                     Money.all.collect(&:alpha_code))
    end
  end

  describe "#count" do
    it "should raise error on empty sql" do
      expect { SqlRecord.new.count }.should raise_error
    end

    it "should return count of records" do
      count = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       count
      count.should eq(Asset.count + Money.count)
    end

    it "should return 0 if records is not exist" do
      Money.delete_all
      Asset.delete_all
      count = SqlRecord.union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       count
      count.should eq(0)
    end
  end

  describe "#paginate" do
    it "should return limited data" do
      4.times { create(:asset) }
      4.times { create(:money) }
      data = SqlRecord.paginate(page: 1, per_page: 5).
                       union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       select("tag")
      data.count.should eq(5)
      data = SqlRecord.paginate(page: 2, per_page: 5).
                       union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       select("tag")
      data.count.should eq(3)
      data = SqlRecord.paginate(page: 1).
                       union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       all
      data.count.should eq(8)
      data = SqlRecord.paginate(page: 2).
                       union(Asset.select(:tag).to_sql,
                             Money.select("alpha_code as tag").to_sql).
                       all
      data.count.should eq(0)
    end
  end
end
