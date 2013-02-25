# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

FactoryGirl.define do
  sequence :tag do |n|
    "some tag ##{n}"
  end

  factory :entity do
    tag
  end

  factory :asset do
    tag
    sequence(:mu) { |n| "mu#{n}" }
  end

  factory :money do
    sequence(:alpha_code) { |n| "MN#{n}" }
    sequence(:num_code) { |n| n }
  end

  factory :chart do
    currency { |chart| chart.association(:money) }
  end

  factory :deal do
    tag
    give { |deal| deal.association(:deal_give, :strategy => :build) }
    take { |deal| deal.association(:deal_take, :strategy => :build) }
    entity
    rate 1.0
    execution_date nil
    compensation_period nil
  end

  factory :state do
    start DateTime.now
    amount 1.0
    side StateAction::ACTIVE
    deal #{ |state| state.association(:deal) }
  end

  factory :balance do
    start DateTime.now.change(hour: 12)
    amount 1.0
    value 1.0
    side Balance::ACTIVE
    deal
  end

  factory :fact do
    day DateTime.now.change(hour: 12)
    amount 1.0
    resource { |fact| fact.association(:money) }
    from { |fact| fact.association(:deal,
                                   :take => FactoryGirl.build(:deal_take,
                                                              :resource => fact.resource)) }
    to { |fact| fact.association(:deal,
                                 :give => FactoryGirl.build(:deal_give,
                                                            :resource => fact.resource)) }
  end

  factory :txn do
    fact #{ |txn| txn.association(:fact) }
  end

  factory :income do
    start DateTime.now
    side Income::PASSIVE
    value 1.0
  end

  factory :quote do
    money #{ |quote| quote.association(:money) }
    rate 1.0
    day DateTime.now
  end

  factory :rule do
    tag
    deal #{ |rule| rule.association(:deal) }
    from { |rule| rule.association(:deal) }
    to { |rule| rule.association(:deal) }
    fact_side false
    change_side true
    rate 1.0
  end

  factory :mu do
    tag
  end

  factory :country do
    tag
  end

  factory :person do
    sequence(:first_name) { |n| "FirstName#{n}" }
    sequence(:second_name) { |n| "SecondName#{n}" }
    birthday Date.today
    place_of_birth "Minsk"
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@aasii.org" }
    password "secret"
    password_confirmation { |user| user.password }
    entity #{ |user| user.association(:entity) }
    sequence(:reset_password_token) { |n| "anything#{n}" }
  end

  factory :legal_entity do
    sequence(:name) { |n| "Some legal entity#{n}" }
    country #{ |l| l.association(:country) }
    identifier_name "VATIN"
    identifier_value "500100732259"
  end

  factory :place do
    tag
  end

  factory :waybill do
    sequence(:document_id) { |n| "document#{n}" }
    distributor { |waybill| waybill.association(:legal_entity) }
    distributor_place { |waybill| waybill.association(:place) }
    storekeeper { |waybill| waybill.association(:entity) }
    storekeeper_place { |waybill| waybill.association(:place) }
    created DateTime.now
  end

  factory :term do
    place
    type { |term| term.association(:classifier) }
    resource { |term| term.association(:asset) }
  end

  factory :deal_give, :parent => :term do
    side false
  end

  factory :deal_take, :parent => :term do
    side true
  end

  factory :allocation do
    foreman { |allocation| allocation.association(:entity) }
    foreman_place { |allocation| allocation.association(:place) }
    storekeeper { |allocation| allocation.association(:entity) }
    storekeeper_place { |allocation| allocation.association(:place) }
    created Date.today
  end

  factory :credential do
    user
    place
    sequence(:document_type) { |n| "document_type#{n}" }
  end

  factory :group do
    tag
    manager { |group| group.association(:user) }
  end

  factory :classifier do
    tag
  end

  factory :notification do
    sequence(:title) { |n| "title#{n}" }
    sequence(:message) { |n| "msg#{n}" }
    date DateTime.now
    notification_type 1
  end



  factory :price, class: Estimate::Price do
    sequence(:date) { |i| Date.new(2000 + i, 1, 1)}
    direct_cost 10.0
    bo_m
    catalog
  end

  factory :bo_m, class: Estimate::BoM do
    resource { |b| b.association(:asset) }
    sequence(:uid) { |n| "uid##{n}" }
    catalog
  end

  factory :document, class: Estimate::Document do
    sequence(:title) { |n| "document##{n}" }
    data "<html><head><title>Title of document</title></head><body><h1>Data of document</h1></body></html>"
  end

  factory :catalog, class: Estimate::Catalog do
    sequence(:tag) { |n| "catalog##{n}" }
    parent_id nil
    document_id nil
  end

  factory :project, class: Estimate::Project do
    place
    customer { |pr| pr.association(:entity)}
    boms_catalog  { |b| b.association(:catalog) }
    prices_catalog  { |b| b.association(:catalog) }
  end

  factory :local, class: Estimate::Local do
    sequence(:tag) { |n| "local##{n}" }
    project
    date DateTime.now
    canceled nil
  end
end
