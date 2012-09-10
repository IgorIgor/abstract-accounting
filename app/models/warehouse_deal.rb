# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module WarehouseDeal
  extend ActiveSupport::Concern

  module ClassMethods
    def act_as_warehouse_deal(args = { from: :from, to: :to})
      has_paper_trail
      include Statable
      act_as_statable
      include Commentable

      class_attribute :warehouse_fields

      warehouse_entity(args[:from], { methods: { entity: :from, place: :give } })
      warehouse_entity(args[:to], { methods: { entity: :to, place: :take } })
      self.warehouse_fields = args

      validates_presence_of :created

      belongs_to :deal
      has_many :comments, :as => :item

      before_save :before_warehouse_deal_save
      after_save :after_warehouse_deal_save
      class_attribute :before_item_save_callback

      attr_accessor :fact

      after_apply :send_comment_after_apply
      after_reverse :send_comment_after_reverse
      after_cancel :send_comment_after_cancel

      before_apply :apply_fact
      before_reverse :reverse_fact
    end

    def before_item_save(callback)
      self.before_item_save_callback = callback
    end

    def warehouse_entity(name, opts = { methods: { entity: :from, place: :give } })
      attr_name = name.kind_of?(String) ? name : name.to_s
      attr_place = "#{attr_name}_place"
      attr_writer attr_name.to_sym, attr_place.to_sym
      validates_presence_of attr_name.to_sym, attr_place.to_sym

      send :define_method, attr_name.to_sym do
        self.instance_variable_get("@#{attr_name}".to_sym) ||
            (self.deal.nil? ? nil : self.deal.rules.first.
                send(opts[:methods][:entity]).entity)
      end

      send :define_method, attr_place.to_sym do
        self.instance_variable_get("@#{attr_place}".to_sym) ||
            (self.deal.nil? ? nil : self.deal.send(opts[:methods][:place]).place)
      end
    end

    def warehouses
      Credential.class_eval do
        def tag
          self.place.tag
        end
        def storekeeper
          self.user.entity.tag
        end
      end
      Credential.find_all_by_document_type(self.name)
    end

    def extract_warehouse(warehouse_id)
      c = Credential.find(warehouse_id)
      { storekeeper_place_id: c.place_id,
        storekeeper_id: c.user.entity_id,
        storekeeper_type: Entity.name }
    end
  end

  def initialize_warehouse_attrs(attrs = nil)
    if attrs
      self.class.warehouse_fields.values.each do |value|
        id = "#{value}_id".to_sym
        type = "#{value}_type".to_sym
        place = "#{value}_place_id".to_sym
        if attrs[id] && attrs[type]
          self.instance_variable_set("@#{value}".to_sym,
                                     attrs[type].constantize.find(attrs[id]))
        end
        if attrs[place]
          self.instance_variable_set("@#{value}_place".to_sym,
                                     Place.find(attrs[place]))
        end
        attrs.delete(id) if attrs.has_key?(id)
        attrs.delete(type) if attrs.has_key?(type)
        attrs.delete(place) if attrs.has_key?(place)
      end
    end
    attrs
  end

  def add_item(attrs = {})
    @items = Array.new unless @items
    resource = Asset.send("#{self.class.warehouse_fields[:item]}_by_tag_and_mu",
                          attrs[:tag], attrs[:mu])
    attrs[:object] = self

    @items << WaybillItem.new(object: self, amount: attrs[:amount],
                              resource: resource, price: attrs[:price])
  end

  def items
    @items = Array.new unless @items
    if @items.empty? and !self.deal.nil?
      self.deal.rules.each do |rule|
        @items << WaybillItem.new(object: self, resource: rule.from.take.resource,
                                  amount: rule.rate,
                                  price: (1.0 / rule.from.rate).accounting_norm)
      end
    end
    @items
  end

  def warehouse_id
    klass = self.class.name
    if self.storekeeper
      storekeeper_id = self.storekeeper.id
      storekeeper_place_id = self.storekeeper_place.id
      c = Credential.
            where{(place_id == my{storekeeper_place_id}) & (document_type == my{klass})}.
            where{user_id.in(User.where{entity_id == my{storekeeper_id}}.pluck(:id))}.first
      c ? c.id : nil
    elsif PaperTrail.whodunnit
      user = PaperTrail.whodunnit
      if user.root?
        nil
      else
        c = Credential.where{(user_id == my{user.id}) & (document_type == my{klass})}.first
        c ? c.id : nil
      end
    else
      nil
    end
  end

  def before_warehouse_deal_save
    if self.new_record?
      settings = self.class.warehouse_fields

      self.deal = Deal.new(entity: self.storekeeper, rate: 1.0, isOffBalance: true,
        tag: I18n.t("activerecord.attributes.#{self.class.name.downcase}.deal.tag",
                    id: self.document_id))
      shipment = Asset.find_or_create_by_tag('Warehouse Shipment')
      return false if self.deal.build_give(place: self.send("#{settings[:from]}_place"),
                                           resource: shipment).nil?
      return false if self.deal.build_take(place: self.send("#{settings[:to]}_place"),
                                           resource: shipment).nil?
      return false unless self.deal.save
      self.deal_id = self.deal.id

      @items.each do |item, idx|
        return false if self.class.before_item_save_callback &&
                        !send(self.class.before_item_save_callback, item)

        from_item = item.warehouse_deal(
            settings[:from_currency] ? settings[:from_currency].call() : nil,
            self.send("#{settings[:from]}_place"),
            self.send(settings[:from]))
        return false if from_item.nil?

        to_item = item.warehouse_deal(
            settings[:to_currency] ? settings[:to_currency].call() : nil,
            self.send("#{settings[:to]}_place"),
            self.send(settings[:to]))
        return false if to_item.nil?

        return false if self.deal.rules.create(tag: "#{deal.tag}; rule#{idx}",
          from: from_item, to: to_item, fact_side: false,
          change_side: true, rate: item.amount).nil?
      end
    end
    true
  end

  def after_warehouse_deal_save
    send_comment self, I18n.t(
          "activerecord.attributes.#{self.class.name.downcase}.comment.create")
  end

  def send_comment_after_apply
    send_comment self, I18n.t(
        "activerecord.attributes.#{self.class.name.downcase}.comment.apply")
  end

  def send_comment_after_reverse
    send_comment self, I18n.t(
        "activerecord.attributes.#{self.class.name.downcase}.comment.reverse")
  end

  def send_comment_after_cancel
    send_comment self, I18n.t(
        "activerecord.attributes.#{self.class.name.downcase}.comment.cancel")
  end

  def apply_fact
    self.fact = Fact.create(amount: 1.0, resource: self.deal.give.resource,
                            day: DateTime.current.change(hour: 12), to: self.deal)

    !self.fact.nil?
  end

  def reverse_fact
    self.fact = Fact.create(amount: -1.0, resource: self.deal.give.resource,
                            day: DateTime.current.change(hour: 12), to: self.deal)
    !self.fact.nil?
  end
end
