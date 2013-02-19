# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
node(:id) { @local.id }
node(:type) { @local.class.name }
child(@local => :local) do
  attributes :tag, :date
  node(:approved) { |l| l.approved.strftime('%Y-%m-%d') if l.approved }
  node(:canceled) { |l| l.canceled.strftime('%Y-%m-%d') if l.canceled }
end
child(@local.boms_catalog => :boms_catalog) { attributes :id }
child(@local.prices_catalog => :prices_catalog) { attributes :id }
child(@local.items => :items) do
  attributes :amount
  node(:correct) { true }
  node(:total_direct_cost) { |l| l.total(:direct_cost) }
  node(:total_workers_cost) { |l| l.total(:workers_cost) }
  node(:total_machinery_cost) { |l| l.total(:machinery_cost) }
  node(:total_drivers_cost) { |l| l.total(:drivers_cost) }
  node(:total_materials_cost) { |l| l.total(:materials_cost) }
  child(:price) do
    attributes :id, :direct_cost, :workers_cost, :machinery_cost, :drivers_cost, :materials_cost
    child(:bo_m => :bom) do
      attributes :id, :uid, :workers_amount, :avg_work_level, :drivers_amount
      child(:resource => :resource) do
        attributes :tag, :mu
      end
      child(:machinery => :machinery) do
        attributes :uid, :amount
        glue(:resource => :resource) do
          attributes :tag, :mu
        end
      end
      child(:materials => :materials) do
        attributes :uid, :amount
        glue(:resource => :resource) do
          attributes :tag, :mu
        end
      end
    end
  end
end
