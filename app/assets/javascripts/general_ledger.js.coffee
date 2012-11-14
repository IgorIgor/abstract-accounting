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
    constructor: (data, params = {}) ->
      @url = '/general_ledger/data.json'
      @date = ko.observable(new Date())
      unless $.isEmptyObject(params)
        @date($.datepicker.parseDate('yy-mm-dd', params.date))

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
      @filterData()

    toTranscript: (object) =>
      filter =
        date_from: object.day
        date_to: object.day
        deal_id: if object.deal_debit then object.deal_debit else object.deal_credit
      location.hash = "transcripts?#{$.param(filter)}"

