# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Deal < ActiveRecord::Base
  has_paper_trail

  validates :tag, :rate, :entity_id, :entity_type, :give, :take, :presence => true
  validates_uniqueness_of :tag, :scope => [:entity_id, :entity_type]
  belongs_to :entity, :polymorphic => true
  has_many :states
  has_many :balances
  has_many :rules
  has_many :terms
  has_many :to_facts, :class_name => Fact, :foreign_key => :to_deal_id
  has_one :give, :class_name => "Term", :conditions => {:side => false}
  has_one :take, :class_name => "Term", :conditions => {:side => true}
  has_one :deal_state
  has_one :waybill
  has_one :allocation
  has_one :limit
  before_save :before_save

  custom_sort(:name) do |dir|
    query = "case entity_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
    joins{entity(Entity).outer}.joins{entity(LegalEntity).outer}.order("#{query} #{dir}")
  end

  custom_sort(:give) do |dir|
    query = "case resource_type
                  when 'Asset' then assets.tag
                  when 'Money' then money.alpha_code
             end"
    joins{give.resource(Asset).outer}.joins{give.resource(Money).outer}.
        order("#{query} #{dir}")
  end

  custom_sort(:take) do |dir|
    query = "case resource_type
                  when 'Asset' then assets.tag
                  when 'Money' then money.alpha_code
             end"
    joins{take.resource(Asset).outer}.joins{take.resource(Money).outer}.
        order("#{query} #{dir}")
  end

  def self.income
    income = Deal.where(:id => INCOME_ID).first
    if income.nil?
      income = Deal.new :tag => "profit and loss", :rate => 1.0
      income.id = INCOME_ID
    end
    income
  end

  def income?
    self.id == INCOME_ID
  end

  def state(day = nil)
    states.where(:start =>
      (unless day.nil?
        states.where("start <= ?", day)
      else
        states
      end).maximum("start")
    ).where("paid > ? OR paid is NULL", day).first
  end

  def balance
    balances.where("balances.paid IS NULL").first
  end

  def update_by_fact(fact)
    return false if fact.nil?
    return true if self.income?
    state = self.state

    if state.nil? && !self.execution_date.nil? && fact.day > self.execution_date
      raise 'warning # execution'
    end

    state = self.states.build(:start => fact.day) if state.nil?
    if !state.new_record? && state.start < fact.day
      state_clone = self.states.build(state.attributes)
      return false unless state.update_attributes(:paid => fact.day)
      state = state_clone
      state.start = fact.day
    elsif !state.new_record? && state.start > fact.day
      raise "State start day is great then fact day"
    end

    return false unless state.update_amount(self.id == fact.from_deal_id ? State::PASSIVE : State::ACTIVE,
                                            fact.amount)

    if self.states(:force_update).empty?
      if self.limit.side == Limit::PASSIVE && self.id == fact.from_deal_id
        #raise "not ok! need TO first"
      end
      if self.limit.side == Limit::ACTIVE && self.id == fact.to_deal_id
        #raise "not ok! need FROM first"
      end
    end

    if self.limit.side == Limit::PASSIVE
      amount = state.amount / self.rate
    else
      amount = state.amount
    end

    if self.limit.amount > 0 && amount > self.limit.amount
      #raise "Ohoho amount > limit! it's not goood"
    end

    if !state.zero? && !self.execution_date.nil? && (self.execution_date + self.compensation_period.days) < fact.day
      raise 'warning # compensation'
    end

    return state.destroy if state.zero? && !state.new_record?
    return true if state.zero? && state.new_record?
    state.save
  end

  def update_by_txn(txn)
    return false if txn.nil? or txn.fact.nil?
    return true if self.income?
    balance = self.balance
    balance = self.balances.build :start => txn.fact.day if balance.nil?
    if !balance.new_record? && balance.start < txn.fact.day
      balance_clone = self.balances.build(balance.attributes)
      return false unless balance.update_attributes(:paid => txn.fact.day)
      balance = balance_clone
      balance.start = txn.fact.day
    elsif !balance.new_record? && balance.start > txn.fact.day
      raise "Balance start day is greater then fact day"
    end
    return false unless balance.update_value(self.id == txn.fact.from.id ? Balance::PASSIVE : Balance::ACTIVE,
                                              txn.fact.amount, txn.value)
    return balance.destroy if balance.zero? && !balance.new_record?
    return true if balance.zero? && balance.new_record?
    balance.save
  end

  def facts(start, stop)
    if self.income?
      Fact
    else
      Fact.where("(facts.from_deal_id = :id OR facts.to_deal_id = :id)",
                  :id => self.id)
    end.where("facts.day > :start AND facts.day < :stop",
              :start => DateTime.civil(start.year, start.month, start.day, 0, 0, 0),
              :stop => DateTime.civil(stop.year, stop.month, stop.day, 13, 0, 0)).all
  end

  def txns(start, stop)
    scoped_txn = Txn.joins("INNER JOIN facts ON facts.id = txns.fact_id").
        where("facts.day > :start AND facts.day < :stop",
              :start => DateTime.civil(start.year, start.month, start.day, 0, 0, 0),
              :stop => DateTime.civil(stop.year, stop.month, stop.day, 13, 0, 0))
    if self.income?
      scoped_txn.where("txns.status = 1")
    else
      scoped_txn.where("(facts.from_deal_id = :id OR facts.to_deal_id = :id)",
                  :id => self.id)
    end
  end

  def limit_amount
    self.limit.nil? ? 0 : self.limit.amount
  end

  def limit_side
    if self.limit.nil?
      Limit::PASSIVE
    else
      self.limit.side
    end
  end

  private
  INCOME_ID = 0

  def before_save
    self.build_limit(side: Limit::PASSIVE, amount: 0) if self.limit.nil?
  end
end

# vim: ts=2 sts=2 sw=2 et:
