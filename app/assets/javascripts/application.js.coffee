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
          delete hash[key] unless hash[key] == undefined || value.length ||
                                  (typeof hash[key] == 'number')

    null until $.map(normalize(hash), (c) -> c).toString().indexOf(true) == -1
    hash

  class self.ObjectViewModel
    constructor: (object, route, readonly = false)->
      @readonly = ko.observable(readonly)
      @object = ko.mapping.fromJS(object)
      @route = route
      $('.paginate').hide()

    back: -> location.hash = 'inbox'

    save: =>
      ajaxRequest('POST', "/#{@route}", ko.mapping.toJS(@object))

  class self.CommentableViewModel extends ObjectViewModel
    constructor: (object, route, readonly = false)->
      super(object, route, readonly)
      @message = ko.observable('')
      @messages = ko.observableArray([])
      @getMessages()

    getMessages: =>
      params =
        item_id: @object.id
        item_type: @object.type

      $.getJSON('/comments.json', params, (comments) =>
        @messages(comments)
      )

    saveComment: =>
      params =
        comment:
          item_id: @object.id
          item_type: @object.type
          message: @message

      $.ajax(
        type: 'post'
        url: 'comments'
        data: params
        complete: (data) =>
          if data.responseText == 'success'
            @message('')
            @getMessages()
      )

  class self.EditableObjectViewModel extends ObjectViewModel
    constructor: (object, route, readonly = false)->
      super(object, route, readonly)
      @method = 'POST'
      @id_presence = ko.observable(object.id?)

    edit: =>
      @readonly(false)
      @method = 'PUT'
      location.hash = "#documents/#{@route}/#{@object.id()}/edit"

    save: =>
      url = "/#{@route}"
      if @method == 'PUT'
        url = "/#{@route}/#{@object.id()}"
      ajaxRequest(@method, url, ko.mapping.toJS(@object))

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
      @getPaginateData()

    next: =>
      @page(@page() + 1)
      @getPaginateData()

    getPaginateData: =>
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
                when 'users'
                  new UserViewModel(object)
                when 'groups'
                  new GroupViewModel(object)

              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
        this.get('#documents/:type/:id', ->
          id = this.params.id
          type = this.params.type
          $.get("#{type}/preview", {}, (form) ->
            $.getJSON("#{type}/#{id}.json", {}, (object) ->
              viewModel = switch type
                when 'distributions'
                  new DistributionViewModel(object, true)
                when 'waybills'
                  new WaybillViewModel(object, true)
                when 'users'
                  new UserViewModel(object, true)
                when 'groups'
                  new GroupViewModel(object, true)

              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
        this.get('#:report', ->
          report = this.params.report
          $.get("/#{report}", {}, (form) ->
            $.getJSON("/#{report}/data.json", {}, (data) ->
              toggleSelect(report)

              viewModel = switch report
                when 'warehouses'
                  new WarehouseViewModel(data)
                when 'general_ledger'
                  new GeneralLedgerViewModel(data)
                when 'balance_sheet'
                  new BalanceSheetViewModel(data)
                when 'transcripts'
                  new TranscriptViewModel(data)
                when 'users'
                  new UsersViewModel(data)
                when 'groups'
                  new GroupsViewModel(data)

              $('#container_documents').html(form)
              ko.cleanNode($('#main').get(0))
              ko.applyBindings(viewModel, $('#main').get(0))
            )
          )
        )
      ).run()

      location.hash = 'inbox' if $('#main').length

  ko.applyBindings(new HomeViewModel(), $('#body').get(0))
