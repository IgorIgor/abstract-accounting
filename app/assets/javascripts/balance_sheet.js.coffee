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
      @url = '/balance_sheet/data.json'
      @balances_date = ko.observable(new Date())
      @mu = ko.observable('natural')
      @total_debit = ko.observable(data.total_debit)
      @total_credit = ko.observable(data.total_credit)
      super(data)

      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page

    filter: =>
      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
      $.getJSON(@url, @params, (data) =>
        @documents(data.objects)
        @page(1)
        @count(data.count)
        @range(@rangeGenerate())
        @total_debit(data.total_debit)
        @total_credit(data.total_credit)
      )
