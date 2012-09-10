# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe AllocationsController do
  let(:ivanov) { create(:entity) }
  let(:moscow) { create(:place) }
  let(:user) do
    u = create(:user, entity: ivanov)
    create(:credential, user: u, document_type: Allocation.name, place: moscow)
    u
  end

  before :all do
    create(:chart)
    minsk = create(:place)
    petrov = create(:entity)

    wb1 = build(:waybill, storekeeper: ivanov,
                          storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!
    wb1.apply

    db1 = build(:allocation, storekeeper: ivanov,
                            storekeeper_place: moscow)
    db1.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db1.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    db1.save!

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!
    wb2.apply

    db2 = build(:allocation, storekeeper: ivanov,
                            storekeeper_place: moscow)
    db2.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db2.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    db2.save!

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!
    wb3.apply

    db3 = build(:allocation, storekeeper: petrov,
                            storekeeper_place: minsk)
    db3.add_item(tag: 'roof', mu: 'rm', amount: 5)
    db3.add_item(tag: 'nails', mu: 'kg', amount: 10)
    db3.save!
  end

  check_authentication AllocationsController
  check_authorization AllocationsController
  check_authorized_load(:user, data: :allocations, list: :list) do |action, user|
    scope =
        case action
          when :data
            Allocation
          when :list
            AllocationReport.with_resources.select_all
        end
    if user.root?
      scope.all
    else
      credential = user.credentials.where{document_type == Allocation.name}.first
      if credential
        scope.by_warehouse(credential.place)
      else
        []
      end
    end
  end
end
