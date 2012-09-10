# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Warehouse
  attr_reader :place, :id, :tag, :real_amount, :exp_amount, :mu

  def initialize(attrs)
    @place = attrs['place']
    @id = attrs['asset_id']
    @tag = attrs['tag']
    @real_amount = Converter.float(attrs['real_amount'])
    @exp_amount = Converter.float(attrs['exp_amount'])
    @mu = attrs['mu']
  end

  def self.all(attrs = {})
    attrs[:select] = 'warehouse'
    warehouse = []
    ActiveRecord::Base.connection.
        execute("#{script(attrs)} #{SqlBuilder.paginate(attrs)}").each do |entry|
      warehouse << Warehouse.new(entry)
    end
    warehouse
  end

  def self.group(attrs = {})
    groups = []
    attrs[:select] = 'group'
    ActiveRecord::Base.connection.
        execute("#{script(attrs)} #{SqlBuilder.paginate(attrs)}").each { |entry|
      groups << { value: entry['group_column'], id: Converter.int(entry['id']) }
    }
    groups
  end

  def self.count(attrs = {})
    attrs[:select] = 'count'
    Converter.int(ActiveRecord::Base.connection.execute(script(attrs))[0]["count"])
  end

  private
  def self.script(attrs)
    unless attrs.nil? || attrs[:select].nil?
      select =
        if attrs[:select] == 'count'
          'COUNT(*) as count'
        elsif attrs[:select] == 'warehouse'
          'places.tag as place, warehouse.*, assets.tag as tag, assets.mu as mu'
        end

      condition = ''

      converter = lambda do |attr|
        case attr.to_s
          when "warehouse_id"
            "places.id"
          when "place"
            "places.tag"
          when "tag"
            "assets.tag"
          when "exp_amount"
            "to_char(warehouse.exp_amount, '9999.99')"
          when "real_amount"
            "to_char(warehouse.real_amount, '9999.99')"
          else
            attr.to_s
        end
      end
      storekeeper = ""
      if attrs.has_key?(:where)
        attrs[:where].each do |attr, value|
          if value.kind_of?(Hash)
            if value.has_key?(:equal)
              condition += " AND #{converter.call(attr)} = '#{value[:equal]}'"
            elsif value.has_key?(:like)
              condition += " AND lower(#{converter.call(attr)}) LIKE '%#{value[:like]}%'"
            elsif value.has_key?(:equal_attr)
              condition += " AND #{converter.call(attr)} = '#{value[:equal_attr]}'"
            end
          end
        end
      end

      if attrs.has_key?(:without)
        condition << " AND warehouse.asset_id NOT IN (#{attrs[:without].join(', ')})"
      end

      group_by = 'T.place_id, T.asset_id'
      select_inner = "T.place_id, T.asset_id"
      inner_join = "
        INNER JOIN places ON warehouse.place_id = places.id
        INNER JOIN assets ON warehouse.asset_id = assets.id"
      if attrs[:group_by]
        select_inner = group_by =
          if attrs[:group_by] == 'place'
            inner_join = "INNER JOIN places ON warehouse.place_id = places.id"
            'T.place_id'
          elsif attrs[:group_by] == 'tag'
            inner_join = "INNER JOIN assets ON warehouse.asset_id = assets.id"
            'T.asset_id'
          end

        if attrs[:select] == 'group'
          select_id =
            if attrs[:group_by] == 'place'
              'warehouse.place_id as id'
            elsif attrs[:group_by] == 'tag'
              'warehouse.asset_id as id'
            end
          select = "#{converter.call(attrs[:group_by])} as group_column, #{select_id}"
        end
      end

      order_by = ''
      order_converter = lambda do |name|
        case name
          when 'exp_amount', 'real_amount'
            name
          else
            converter.call(name)
        end
      end
      if attrs[:order_by]
        type = ''
        type = 'DESC' if attrs[:order_by][:type] == 'desc'
        order_by = "ORDER BY #{order_converter.call(attrs[:order_by][:field])} #{type}"
      end

      "
      SELECT #{select} FROM (
        SELECT #{select_inner},
               SUM(T.real_amount) as real_amount,
               ROUND(CAST (SUM(T.real_amount - T.exp_amount) as NUMERIC), 2) as exp_amount
        FROM (
          SELECT terms.resource_id as asset_id, terms.place_id as place_id,
                 MAX(states.amount) as real_amount, 0.0 as exp_amount
          FROM rules
            INNER JOIN waybills ON waybills.deal_id = rules.deal_id
            INNER JOIN deals ON deals.id = rules.deal_id
            INNER JOIN entities ON entities.id = deals.entity_id
            INNER JOIN states ON states.deal_id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
          WHERE states.paid is NULL
          GROUP BY terms.place_id, terms.resource_id
          UNION
          SELECT terms.resource_id as asset_id, terms.place_id as place_id,
                 0.0 as real_amount, SUM(rules.rate) as exp_amount
          FROM rules
            INNER JOIN allocations ON allocations.deal_id = rules.deal_id
            INNER JOIN deals ON deals.id = rules.deal_id
            INNER JOIN entities ON entities.id = deals.entity_id
            INNER JOIN states ON states.deal_id = rules.from_id
            INNER JOIN terms ON terms.deal_id = rules.from_id AND terms.side = 'f'
            INNER JOIN deal_states ON allocations.deal_id = deal_states.deal_id
                                   AND deal_states.closed IS NULL
          WHERE states.paid is NULL
          GROUP BY terms.place_id, terms.resource_id
        ) T
        GROUP BY #{group_by}
      ) as warehouse
      #{inner_join}
      WHERE warehouse.real_amount > 0.0 AND warehouse.exp_amount > 0.0 #{condition}
      #{order_by}"
    end
  end
end
