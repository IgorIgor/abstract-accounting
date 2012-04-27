# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

$ ->
  class self.BalanceSheetViewModel extends FolderViewModel
    constructor: (data) ->
      data.objects = data
      @balances_date = ko.observable(new Date())
      @select_mu = ko.observable('natural')
      @select_mu.subscribe(@filter)
      super(data)

    filter: =>
      params =
        date: @balances_date().toString()
        mu: @select_mu()
      $.getJSON('/balance_sheet/data.json', params, (data) =>
        @documents(data)
      )
