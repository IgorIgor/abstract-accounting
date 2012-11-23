# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

class TestWarehouseDeal

  class << self
    def has_paper_trail
      @has_paper_trail = true
    end

    def paper_trail_included?
      @has_paper_trail
    end

    def before_save(*args)
    end

    def after_save(*args)
    end

    def has_many(*args)
    end

    def belongs_to(*args)
    end

    def validates_presence_of(*args)
    end

    def includes(*args)
    end

    def scope(*args)
    end
  end
  include Helpers::WarehouseDeal
  act_as_warehouse_deal
end

class TestRecord

end

describe Helpers::WarehouseDeal do
  subject { TestWarehouseDeal }
  it { should be_paper_trail_included }
  it { should include(Helpers::Statable) }
  it { should include(Helpers::Commentable) }

  describe "#warehouse_attr" do
    it "should generate attr accessors" do
      TestWarehouseDeal.class_exec do
        warehouse_attr :custom, class: TestRecord
        warehouse_attr :pcustom, polymorphic: true
      end

      object = TestWarehouseDeal.new
      object.should respond_to :custom
      object.should respond_to "custom_id"
      object.should respond_to "custom="
      object.should respond_to "custom_id="

      object.should respond_to :pcustom
      object.should respond_to "pcustom_id"
      object.should respond_to "pcustom_type"
      object.should respond_to "pcustom="
      object.should respond_to "pcustom_id="
      object.should respond_to "pcustom_type="
    end
  end
end
