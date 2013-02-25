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
  node :deal_id do |txn|
    if txn.fact.from
      if @transcript.deal.id == txn.fact.from.id
        txn.fact.to.id
      else
        txn.fact.from.id
      end
    else
      nil
    end
  end
  node :date do |txn|
    txn.fact.day.strftime('%Y-%m-%d')
  end
  node :account do |txn|
    if txn.fact.from
      if @transcript.deal.id == txn.fact.from.id
        txn.fact.to.tag
      else
        txn.fact.from.tag
      end
    else
      "#{I18n.t 'views.transcripts.not_exist'}"
    end
  end
  node(:type) { |txn| @transcript.deal.id == txn.fact.to.id ? 'debit' : 'credit' }
  node(:value) { |txn| txn.value.to_s }
  node(:amount) { |txn| txn.fact.amount.to_s }
end
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @transcript.nil? ? 0 : @transcript.count }
child(true => :from) do
  node(:type) do
    if @transcript && @transcript.opening && @transcript.opening.side == Balance::PASSIVE
      'debit'
    else
      'credit'
    end
  end
  node(:value) do
    (@transcript && @transcript.opening) ? @transcript.opening.value.to_s : '0.0'
  end
  node(:amount) do
    (@transcript && @transcript.opening) ? @transcript.opening.amount.to_s : '0.0'
  end
end
child(true => :to) do
  node(:type) do
    if @transcript && @transcript.closing && @transcript.closing.side == Balance::PASSIVE
      'debit'
    else
      'credit'
    end
  end
  node(:value) do
    (@transcript && @transcript.closing) ? @transcript.closing.value.to_s : '0.0'
  end
  node(:amount) do
    (@transcript && @transcript.closing) ? @transcript.closing.amount.to_s : '0.0'
  end
end
child(true => :totals) do
  child(true => :debit) do
    node(:amount) { @transcript ? @transcript.total_debits.to_s : '0.0' }
    node(:value) { @transcript ? @transcript.total_debits_value.to_s : '0.0' }
    node(:diff) { @transcript ? @transcript.total_debits_diff.to_s : '0.0' }
  end
  child(true => :credit) do
    node(:amount) { @transcript ? @transcript.total_credits.to_s : '0.0' }
    node(:value) { @transcript ? @transcript.total_credits_value.to_s : '0.0' }
    node(:diff) { @transcript ? @transcript.total_credits_diff.to_s : '0.0' }
  end
end
if @transcript
  child(@transcript.deal => :deal) do
    attributes :id, :tag
  end
end
