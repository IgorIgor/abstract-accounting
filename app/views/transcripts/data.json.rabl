# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@transcripts => :objects) do
  node :date do |txn|
    txn.fact.day
  end
  node :account do |txn|
    if @transcript.deal.id == txn.fact.from.id
      txn.fact.to.tag
    else
      txn.fact.from.tag
    end
  end
  node :debit do |txn|
    if @transcript.deal.id == txn.fact.to.id
      if @mu == 'natural'
        txn.fact.amount.to_s
      else
        txn.value.to_s
      end
    else
      nil
    end
  end
  node :credit do |txn|
    if @transcript.deal.id == txn.fact.from.id
      if @mu == 'natural'
        txn.fact.amount.to_s
      else
        txn.value.to_s
      end
    else
      nil
    end
  end
end
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @transcript.nil? ? 0 : @transcript.count }
node (:from_debit) do
  if @transcript.nil? || @transcript.opening.nil? ||
      @transcript.opening.side != Balance::PASSIVE
    '0.0'
  else
    if @mu == 'natural'
      @transcript.opening.amount.to_s
    else
      @transcript.opening.value.to_s
    end
  end
end
node (:from_credit) do
  if @transcript.nil? || @transcript.opening.nil? ||
      @transcript.opening.side != Balance::ACTIVE
    '0.0'
  else
    if @mu == 'natural'
      @transcript.opening.amount.to_s
    else
      @transcript.opening.value.to_s
    end
  end
end
node (:to_debit) do
  if @transcript.nil? || @transcript.closing.nil? ||
      @transcript.closing.side != Balance::PASSIVE
    '0.0'
  else
    if @mu == 'natural'
      @transcript.closing.amount.to_s
    else
      @transcript.closing.value.to_s
    end
  end
end
node (:to_credit) do
  if @transcript.nil? || @transcript.closing.nil? ||
      @transcript.closing.side != Balance::ACTIVE
    '0.0'
  else
    if @mu == 'natural'
      @transcript.closing.amount.to_s
    else
      @transcript.closing.value.to_s
    end
  end
end
node(:total_debits) do
  if @transcript.nil?
    '0.0'
  else
    if @mu == 'natural'
      @transcript.total_debits.to_s
    else
      @transcript.total_debits_value.to_s
    end
  end
end
node(:total_credits) do
  if @transcript.nil?
    '0.0'
  else
    if @mu == 'natural'
      @transcript.total_credits.to_s
    else
      @transcript.total_credits_value.to_s
    end
  end
end
node(:total_debits_diff) do
  if @mu == 'natural'
    nil
  else
    if @transcript.nil?
      '0.0'
    else
      @transcript.total_debits_diff.to_s
    end
  end
end
node(:total_credits_diff) do
  if @mu == 'natural'
    nil
  else
    if @transcript.nil?
      '0.0'
    else
      @transcript.total_credits_diff.to_s
    end
  end
end
