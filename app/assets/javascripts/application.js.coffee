# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
#= require jquery
#= require jquery-ui
#= require jquery_ujs
#= require jquery.validate
#= require jquery.datepick-ru
#= require sammy
#= require knockout
#= require knockout.mapping
#= require_self
#= require_tree .

$ ->
  self.ajaxRequest = (type, url, params = {}) ->
    $.ajax(
      type: type
      url: url
      data: params
      complete: (data) ->
        if data.responseText == 'success'
          location.hash = 'inbox'
        else
          $('#container_notification').css('display', 'block')
          $('#container_notification ul').css('display', 'block')
          for key, value of JSON.parse(data.responseText)
            $('#container_notification ul')
            .append($("<li class='server-message'>#{key}: #{value}</li>"))
    )

  self.toggleSelect = (id = null) ->
    $('.sidebar-selected').removeClass('sidebar-selected')
    $("##{id}").addClass('sidebar-selected') if id

  self.normalizeHash = (hash) ->
    normalize = (hash) ->
      for key, value of hash
        if (typeof value == 'object') && !$.isEmptyObject(value)
          normalize(value)
        else
          delete hash[key] unless value.length || (typeof hash[key] == 'number')

    null until $.map(normalize(hash), (c) -> c).toString().indexOf(true) == -1
    hash

  class self.ObjectViewModel
    constructor: ->
      $('.paginate').hide()

    back: -> location.hash = 'inbox'

  class self.FolderViewModel
    constructor: (data) ->
      @documents = ko.observableArray(data.objects)

      @page = ko.observable(data.page || 1)
      @per_page = ko.observable(data.per_page)
      @count = ko.observable(data.count)
      @range = ko.observable(@rangeGenerate())

      @params =
        like: @filter
        page: @page
        per_page: @per_page

      $('.paginate').show()

    prev: =>
      @page(@page() - 1)
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

    next: =>
      @page(@page() + 1)
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

    rangeGenerate: =>
      startRange = if @count() then (@page() - 1)*@per_page() + 1 else 0
      endRange = (@page() - 1)*@per_page() + @per_page()
      endRange = @count() if endRange > @count()
      "#{startRange}-#{endRange}"

    filterData: =>
      @page(1)
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

  class HomeViewModel
    constructor: ->
      $.sammy( ->
        this.get('#inbox', ->
          $.get('/inbox', {}, (form) ->
            $.getJSON('/inbox_data.json', {}, (objects) ->
              toggleSelect('inbox')
              $('#container_documents').html(form)
              ko.cleanNode($('#main').get(0))
              ko.applyBindings(new InboxViewModel(objects), $('#main').get(0))
            )
          )
        )
        this.get('#documents/:type/new', ->
          type = this.params.type
          $.get("/#{type}/preview", {}, (form) ->
            $.getJSON("/#{type}/new.json", {}, (object) ->
              toggleSelect()

              viewModel = switch type
                when 'distributions'
                  new DistributionViewModel(object)
                when 'waybills'
                  new WaybillViewModel(object)

              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
        this.get('#warehouses', ->
          $.get('/warehouses', {}, (form) ->
            $.getJSON('/warehouses/data.json', {}, (data) ->
              toggleSelect('warehouses')
              $('#container_documents').html(form)
              ko.cleanNode($('#main').get(0))
              ko.applyBindings(new WarehouseViewModel(data), $('#main').get(0))
            )
          )
        )
        this.get('#general_ledger', ->
          $.get('/general_ledger', {}, (form) ->
            $.getJSON('/general_ledger/data.json', {}, (data) ->
              toggleSelect('general_ledger')
              $('#container_documents').html(form)
              ko.cleanNode($('#main').get(0))
              ko.applyBindings(new GeneralLedgerViewModel(data),
                $('#main').get(0))
            )
          )
        )
        this.get('#balance_sheet', ->
          $.get('/balance_sheet', {}, (form) ->
            $.getJSON('/balance_sheet/data.json', {}, (data) ->
              toggleSelect('balance_sheet')
              $('#container_documents').html(form)
              ko.cleanNode($('#main').get(0))
              ko.applyBindings(new BalanceSheetViewModel(data),
                $('#main').get(0))
            )
          )
        )
      ).run()

      location.hash = 'inbox' if $('#main').length

  ko.applyBindings(new HomeViewModel(), $('#body').get(0))
