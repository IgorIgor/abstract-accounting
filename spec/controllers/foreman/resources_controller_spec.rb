# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Foreman::ResourcesController do
  let(:ivanov) { create(:entity) }
  let(:moscow) { create(:place) }
  let(:user) do
    u = create(:user, entity: ivanov)
    create(:credential, user: u, document_type: WarehouseForemanReport.name, place: moscow)
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

  check_authentication WarehouseForemanReport
  check_authorization WarehouseForemanReport
  check_authorized_load(:user, data: :resources) do |action, user|
    if user.root?
      []
    else
      credential = user.credentials.where{document_type == WarehouseForemanReport.name}.first
      if credential
        args = { warehouse_id: user.credentials.first.place_id,
                 foreman_id: user.entity_id,
                  start: DateTime.current.beginning_of_month,
                  stop: DateTime.current, page: 1,
                  per_page: Settings.root.per_page.to_i }
        WarehouseForemanReport.all(args)
      else
        []
      end
    end
  end
end
