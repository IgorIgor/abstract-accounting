# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Document < Version
  def self.documents
    [Waybill.name, Allocation.name, User.name, Group.name]
  end

  def document_id
    self.item.id
  end

  def document_name
    self.item.class.name
  end

  def document_content
    klass_associations = self.item.class.reflect_on_all_associations(:belongs_to)
    if self.item.class.method_defined?(:storekeeper)
      self.item.storekeeper.tag
    elsif klass_associations.any? { |assoc| assoc.name == :entity }
      self.item.entity.tag
    else
      self.item.tag
    end
  end

  def document_created_at
    self.item.versions.first.created_at
  end

  def document_updated_at
    self.item.versions.last.created_at
  end

  scope :lasts, joins('INNER JOIN
                        (SELECT item_id, MAX(created_at) as last_create
                        FROM versions GROUP BY item_id, item_type) grouped
                      ON versions.item_id = grouped.item_id AND
                      versions.created_at = grouped.last_create')

  def self.by_user(user)
    if user.root?
      return where{item_type.in(Document.documents)}
    end
    if !user.managed_documents.empty?
      where{item_type.in(user.managed_documents)}
    elsif user.documents.empty?
      where{item_type == ""}
    else
      versions_scope = scoped
      versions_scope = versions_scope.where{item_type.in(user.documents)}
      versions_scope = versions_scope.where do
        scope = nil
        user.credentials.each do |c|
          if c.document_type == Waybill.name
            tmp_scope = id.in(
                versions_scope.joins{item(c.document_type.camelize.constantize).deal.take}.
                    where{(item.deal.entity_id == user.entity_id) &
                          (item.deal.take.place_id == c.place_id)}
            )
          elsif c.document_type == Allocation.name
            tmp_scope = id.in(
                versions_scope.joins{item(c.document_type.camelize.constantize).deal.give}.
                    where{(item.deal.entity_id == user.entity_id) &
                          (item.deal.give.place_id == c.place_id)}
            )
          else
            tmp_scope = (whodunnit == user.id.to_s)
          end
          scope = scope ? scope | tmp_scope : tmp_scope
        end
        scope
      end
      versions_scope
    end
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

    ids = []
    attrs.each do |klass, expressions|
      expr_scope = scoped
      expressions.each do |field, value|
        expr_scope = expr_scope.joins do
          scope = item(klass.to_s.camelize.constantize)
          if value.kind_of?(Hash)
            scope = scope.send("#{field}", value.keys[0].to_s.camelize.constantize)
          end
          scope
        end
        expr_scope = expr_scope.where do
          if value.kind_of?(Hash)
            data = value.values.first
            scope = nil
            data.each do |subfield, match|
              tmp_scope = item.send(field).send(subfield).like "%#{match}%"
              scope = scope ? scope & tmp_scope : tmp_scope
            end
            scope
          else
            if klass.to_s.camelize.constantize.columns_hash[field.to_s].type == :integer
              item.send(field) == value.to_i
            else
              item.send(field).like "%#{value}%"
            end
          end
        end
      end
      ids << expr_scope
    end
    if ids.count > 1
      scoped.where do
        ids.inject(nil) { |memo, version| memo ? memo | id.in(version) : id.in(version) }
      end
    else
      ids.first
    end
  end
end
