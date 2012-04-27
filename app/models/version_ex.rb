# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class VersionEx < Version
  scope :lasts, joins('INNER JOIN
                        (SELECT item_id, MAX(created_at) as last_create
                        FROM versions GROUP BY item_id, item_type) grouped
                      ON versions.item_id = grouped.item_id AND
                      versions.created_at = grouped.last_create')

  def self.by_type types
    where(types.map{|item| "item_type='#{item}'"}.join(' OR '))
  end

  def self.paginate(attrs = {})
    page = 1
    per_page = Settings.root.per_page
    unless attrs.nil?
      unless attrs[:page].nil?
        page = attrs[:page].to_i
      end
      unless attrs[:per_page].nil?
        per_page = attrs[:per_page].to_i
      end
    end

    limit(per_page).offset((page - 1) * per_page)
  end

  def self.filter(attrs = nil)
    return scoped if attrs.nil?

    join = ''
    condition = ''

    attrs.each do |model, fields|
      if fields.kind_of?(Hash)
        table = model.to_s.pluralize

        join <<
          "LEFT JOIN #{table} ON versions.item_type = '#{model.to_s.capitalize}'
                              AND versions.item_id = #{table}.id "

        fields.each_with_index do |(field, value), index|
          if value.kind_of?(Hash)
            value.each do |rel_model, rel_fields|
              rel_table = rel_model.to_s.pluralize
              rel_alias = "#{model}_#{field}"

              join << "LEFT JOIN #{rel_table} AS #{rel_alias}
                        ON #{rel_alias}.id = #{table}.#{field}_id "

              rel_fields.each_with_index do |(rel_field, rel_value), rel_index|
                condition << if index.zero? && rel_index.zero?
                  "#{condition.empty? ? '(' : ') OR ('}"
                else
                  ' AND '
                end
                condition << "lower(#{rel_alias}.#{rel_field}) LIKE '%#{rel_value}%'"
              end
            end
          else
            condition << if index.zero?
              "#{condition.empty? ? '(' : ') OR ('}"
            else
              ' AND '
            end
            condition << "lower(#{table}.#{field}) LIKE '%#{value}%'"
          end
        end
      end
    end
    condition << ')' unless condition.empty?

    joins(join).where(condition)
  end
end
