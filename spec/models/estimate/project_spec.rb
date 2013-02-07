# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Estimate::Project do

  it "should have next behaviour" do
    should validate_presence_of :place_id
    should validate_presence_of :customer_id
    should validate_presence_of :customer_type
    should belong_to :customer
    should belong_to :place
    should have_many Estimate::Project.versions_association_name
  end

  it 'should sort projects' do
    10.times { create(:project) }

    pr = Estimate::Project.sort_by_place_tag('asc')
    pr_test = Estimate::Project.joins{place}.order('places.tag asc')
    pr.should eq pr_test
    pr = Estimate::Project.sort_by_place_tag('desc')
    pr_test = Estimate::Project.joins{place}.order('places.tag desc')
    pr.should eq pr_test

    query = "case customer_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
    pr = Estimate::Project.sort_by_customer_tag('asc')
    pr_test = Estimate::Project.joins{customer(Entity).outer}.
        joins{customer(LegalEntity).outer}.order("#{query} asc")
    pr.should eq pr_test
    pr = Estimate::Project.sort_by_customer_tag('desc')
    pr_test = Estimate::Project.joins{customer(Entity).outer}.
        joins{customer(LegalEntity).outer}.order("#{query} desc")
    pr.should eq pr_test
  end
end
