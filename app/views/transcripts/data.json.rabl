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
    if @deal.id == txn.fact.from.id
      txn.fact.to.tag
    else
      txn.fact.from.tag
    end
  end
  node :debit do |txn|
    if @deal.id == txn.fact.to.id
      txn.fact.amount.to_s
    else
      nil
    end
  end
  node :credit do |txn|
    if @deal.id == txn.fact.from.id
      txn.fact.amount.to_s
    else
      nil
    end
  end
end
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @count }
