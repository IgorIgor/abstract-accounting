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
    entity #{ |deal| deal.association(:entity) }
    rate 1.0
  end

  factory :state do
    start DateTime.now
    amount 1.0
    side StateAction::ACTIVE
    deal #{ |state| state.association(:deal) }
  end

  factory :balance do
    start DateTime.now
    amount 1.0
    value 1.0
    side Balance::ACTIVE
    deal #{ |balance| balance.association(:deal) }
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

  factory :price do
    resource { |price| price.association(:asset) }
    rate 10.0
    price_list_id 1
  end

  factory :price_list do
    resource { |plist| plist.association(:asset) }
    date Date.new(2012, 1, 1)
    tab "sometab"
  end

  factory :bo_m do
    resource { |b| b.association(:asset) }
    tab "sometab"
  end

  factory :bo_m_element do
    resource { |element| element.association(:asset) }
    rate 0.45
    bom_id 1
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
    created Date.today
  end

  factory :term do
    place #{ |term| term.association(:place) }
    resource { |term| term.association(:asset) }
  end

  factory :deal_give, :parent => :term do
    side false
  end

  factory :deal_take, :parent => :term do
    side true
  end

  factory :distribution do
    foreman { |distribution| distribution.association(:entity) }
    foreman_place { |distribution| distribution.association(:place) }
    storekeeper { |distribution| distribution.association(:entity) }
    storekeeper_place { |distribution| distribution.association(:place) }
    created Date.today
    state 0
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
end
