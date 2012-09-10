# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe WaybillsController do
  let(:ivanov) { create(:entity) }
  let(:moscow) { create(:place) }
  let(:user) do
    u = create(:user, entity: ivanov)
    create(:credential, user: u, document_type: Waybill.name, place: moscow)
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

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!
    wb2.apply

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!
    wb3.apply
  end

  check_authentication WaybillsController
  check_authorization WaybillsController
  check_authorized_load(:user, present: :waybills, data: :waybills,
                        list: :list) do |action, user|
    if action == :present
      attrs = {}
      unless user.root?
        credential = user.credentials.where{document_type == Waybill.name}.first
        if credential
          attrs = { where: { warehouse_id: { equal: credential.place_id } } }
        else
          attrs = { where: { warehouse_id: { equal: 0 } } }
        end
      end
      Waybill.in_warehouse(attrs)
    else
      scope =
          case action
            when :data
              Waybill
            when :list
              WaybillReport.with_resources.select_all
          end
      if user.root?
        scope.all
      else
        credential = user.credentials.where{document_type == Waybill.name}.first
        if credential
          scope.by_warehouse(credential.place)
        else
          []
        end
      end
    end
  end
end
