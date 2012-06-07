# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

$ ->
  class self.GeneralLedgerViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/general_ledger/data.json'
      @date = ko.observable(new Date())

      super(data)

      @params =
        page: @page
        per_page: @per_page
        date: @date().toString()

    filter: =>
      @params =
        date: @date().toString()
        page: @page
        per_page: @per_page
      $.getJSON(@url, @params, (data) =>
        @documents(data.objects)
        @page(1)
        @count(data.count)
        @range(@rangeGenerate())
      )
