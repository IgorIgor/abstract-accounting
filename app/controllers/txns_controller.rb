# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class TxnsController < ApplicationController
  def create
    fact = Fact.find(params[:fact_id])
    if fact.txn
      render json: {txn: I18n.t('activerecord.errors.models.txn.already_exist')}
      return
    end
    txn = Txn.new(fact: fact)
    if txn.save
      render json: { result: 'success', id: txn.id }
    else
      render json: txn.errors.full_messages
    end
  end
end
