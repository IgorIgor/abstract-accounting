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
    constructor: (data, params = {}) ->
      @url = '/balance_sheet/data.json'
      @balances_date = ko.observable(new Date())
      @mu = ko.observable('natural')
      @total_debit = ko.observable(data.total_debit)
      @total_credit = ko.observable(data.total_credit)
      @resource_id = ko.observable()
      @entity_id = ko.observable()
      @place_id = ko.observable()
      @selected_balances = []
      @selected = ko.observable(false)

      unless $.isEmptyObject(params)
        @resource_id(params.resource_id) if params.resource_id
        @entity_id(params.entity_id) if params.entity_id
        @place_id(params.place_id) if params.place_id

      super(data)

      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource_id: @resource_id()
        entity_id: @entity_id()
        place_id: @place_id()

    filter: =>
      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource_id: @resource_id()
        entity_id: @entity_id()
        place_id: @place_id()
      $.getJSON(@url, normalizeHash(@params), (data) =>
        @documents(data.objects)
        @page(1)
        @count(data.count)
        @range(@rangeGenerate())
        @total_debit(data.total_debit)
        @total_credit(data.total_credit)
      )

    selectBalance: (object) =>
      element_id = '#balance_' + object.deal_id
      if $(element_id).attr("checked") == 'checked'
        @selected_balances.push(object)
        @selected(true)
      else
        @selected_balances.remove(object)
        if @selected_balances.length == 0
          @selected(false)
      true

    reportOnSelected: () =>
      if @selected_balances.length == 1
        date = @selected_balances[0].date
        filter =
          deal_id: @selected_balances[0].deal_id
          date_from: date
          date_to: date
        location.hash = "transcripts?#{$.param(filter)}"
      else if @selected_balances.length > 1
        date = $.datepicker.formatDate('yy-mm-dd', @balances_date())
        ids = jQuery.map(@selected_balances, (item) -> item.deal_id)
        filter =
          deal_ids: ids
          date: date
        location.hash = "general_ledger?#{$.param(filter)}"
