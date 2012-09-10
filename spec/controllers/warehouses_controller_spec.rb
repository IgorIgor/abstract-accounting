# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'
require 'warehouse'

class Warehouse
  def ==(b)
    self.place == b.place && self.id == b.id && self.real_amount == b.real_amount && self.exp_amount == b.exp_amount
  end
end

describe WarehousesController do
  let(:ivanov) { create(:entity) }
  let(:moscow) { create(:place) }
  let(:minsk) { create(:place) }
  let(:user) do
    u = create(:user, entity: ivanov)
    create(:credential, user: u, document_type: Waybill.name, place: moscow)
    create(:credential, user: u, document_type: Allocation.name, place: moscow)
    u
  end
  let(:user_with_diff_credentials) do
    u = create(:user, entity: ivanov)
    create(:credential, user: u, document_type: Waybill.name, place: moscow)
    create(:credential, user: u, document_type: Allocation.name, place: minsk)
    u
  end

  before :all do
    create(:chart)
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

  check_authentication WarehousesController
  check_authorization WarehousesController
  check_authorized_load(:user, data: :warehouse, group: :warehouse,
                        params: { group: { group_by: 'place' } }) do |action, user|
    scope = Warehouse
    case action
      when :data
        if user.root?
          scope.all
        else
          credential = user.credentials.where{document_type == Waybill.name}.first
          if credential
            scope.all({ where: { warehouse_id: { equal: credential.place_id } } })
          else
            []
          end
        end
      when :group
        if user.root?
          scope.group({ group_by: 'place' }).inject([]) do |mem, item|
                      mem << item.inject({}) do |mem2, (key, value)|
                        mem2[key.to_s] = value
                        mem2
                      end
                    end
        else
          credential = user.credentials.where{document_type == Waybill.name}.first
          if credential
            scope.group({ group_by: 'place',
                          where: { warehouse_id: {
                              equal: credential.place_id } } }).inject([]) do |mem, item|
                                      mem << item.inject({}) do |mem2, (key, value)|
                                        mem2[key.to_s] = value
                                        mem2
                                      end
                                    end
          else
            []
          end
        end
    end
  end
  check_authorized_load(:user_with_diff_credentials, data: :warehouse, group: :warehouse,
                        params: { group: { group_by: 'place' } }) do |action, user|
    scope = Warehouse
    case action
      when :data
        if user.root?
          scope.all
        else
          []
        end
      when :group
        if user.root?
          scope.group({ group_by: 'place' }).inject([]) do |mem, item|
            mem << item.inject({}) do |mem2, (key, value)|
              mem2[key.to_s] = value
              mem2
            end
          end
        else
          []
        end
    end
  end
end
