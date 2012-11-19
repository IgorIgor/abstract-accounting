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
#= require jq.scrollabletabs
#= require jquery.mousewheel
#= require jquery.validate
#= require jquery.datepick-ru
#= require sammy
#= require knockout
#= require knockout.mapping
#= require sticky
#= require i18n
#= require i18n/opentask_translations
#= require_self
#= require_tree .
$ ->

  self.slideShow = (slide_id, arrow_id) ->
    unless $(slide_id).is(":visible")
      $(arrow_id).removeClass('arrow-down-slide')
      $(arrow_id).addClass('arrow-up-slide')
      $(slide_id).slideToggle()

  self.menuShow = (menu, actions) =>
    unless menu.is(":visible")
      actions.removeClass('arrow-right-expand')
      actions.addClass('arrow-down-expand')
      menu.slideToggle()

  self.expander = (id) ->
    parent = $("##{id}").parent()
    switch parent.attr("id")
      when "slide_menu_deals"
        menuShow($('#slide_menu_deals'), $('#arrow_deals_actions'))
        expander(parent.attr("id"))
      when "slide_menu_resources"
        menuShow($('#slide_menu_resources'), $('#arrow_resources_actions'))
        expander(parent.attr("id"))
      when "slide_menu_entities"
        menuShow($('#slide_menu_entities'), $('#arrow_entities_actions'))
        expander(parent.attr("id"))
      when 'slide_menu_conditions'
        slideShow('#slide_menu_conditions', '#arrow_conditions')
      when 'slide_menu_lists'
        slideShow('#slide_menu_lists', '#arrow_lists')
      when 'slide_menu_services'
        slideShow('#slide_menu_services', '#arrow_services')
      else
        false


  self.toggleSelect = (id = null) ->
    $('.sidebar-selected').removeClass('sidebar-selected')
    if id
      $("##{id}").addClass('sidebar-selected')
      expander(id)

  self.normalizeHash = (hash) ->
    normalize = (hash) ->
      for key, value of hash
        if (typeof value == 'object') && !$.isEmptyObject(value)
          normalize(value)
        else
          delete hash[key] unless (value != null) && (hash[key] == undefined ||
                                  value.toString().length ||
                                  (typeof hash[key] == 'number'))

    null until $.map(normalize(hash), (c) -> c).toString().indexOf(true) == -1
    hash

  Array.prototype.remove = (value) ->
    this.splice(this.indexOf(value), 1)

  $(document).ajaxStart( ->
    $('#message_box').text(I18n.t('views.notifications.load'))
    width = $('#message_box').css('width')
    width = - width / 2
    $('#message_box').css({'margin-left': "#{width}", 'left': '50%'})
    $('#message_box').css('display', 'block')
  )

  $(document).ajaxStop( ->
    $('#message_box').css('display', 'none')
  )

  $(document).ajaxError((e, jqXHR, settings) ->
    statusErrorMap =
      "400": I18n.t('views.notifications.bad_request')
      "401": I18n.t('views.notifications.unauth')
      "403": I18n.t('views.notifications.forbidden')
      "500": I18n.t('views.notifications.internal_error')
      "503": I18n.t('views.notifications.unavailable')
    message = I18n.t('views.notifications.error')
    if jqXHR.status
      message = statusErrorMap[jqXHR.status]
    else if e == 'parsererror'
      message = I18n.t('views.notifications.parsererror')
    else if e == 'timeout'
      message = I18n.t('views.notifications.timeout')
    else if e == 'abort'
      message = I18n.t('views.notifications.abort')
    $('#message_box').text(message)
    width = $('#message_box').css('width')
    width = - width / 2
    $('#message_box').css({'margin-left': "#{width}", 'left': '50%'})
    $('#message_box').css({'border-color': "#ec9090", 'background-color': '#ecbbbb'})
    $('#message_box').css('display', 'block')
    setTimeout( ->
      $('#message_box').css('display', 'none')
      $('#message_box').css({'border-color': "#F0C36D", 'background-color': '#F9EDBE'})
    5000)
  )

  class self.ObjectViewModel
    constructor: (object, route, readonly = false)->
      @readonly = ko.observable(readonly)
      @object = ko.mapping.fromJS(object)
      @route = route
      $('.paginate').hide()

    ajaxRequest: (type, url, params = {}) =>
      $.ajax(
        type: type
        url: url
        data: params
        complete: (data) =>
          response = JSON.parse(data.responseText)
          if response['result'] == 'success'
            hash = ''
            if response['id']
              hash = "documents/#{@route}/#{response['id']}"
            else
              hash = location.hash
            $.sammy().refresh() unless location.hash == hash
            location.hash = hash
          else
            $('#container_notification').css('display', 'block')
            $('#container_notification ul').css('display', 'block')
            $('#container_notification ul').empty()
            for msg in JSON.parse(data.responseText, (key, value) -> value)
              $('#container_notification ul')
                  .append($("<li class='server-message'>#{msg}</li>"))
      )

    back: -> history.back()

    save: =>
      @ajaxRequest('POST', "/#{@route}", normalizeHash(ko.mapping.toJS(@object)))

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
      @ajaxRequest(@method, url, normalizeHash(ko.mapping.toJS(@object)))

  class self.CommentableViewModel extends EditableObjectViewModel
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

  class self.StatableViewModel extends CommentableViewModel
    constructor: (object, route, readonly = false)->
      super(object, route, readonly)

    apply: =>
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/apply")

    cancel: =>
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/cancel")

    reverse: =>
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/reverse")

    getState: (state) ->
      switch state
        when 0 then I18n.t('views.statable.unknown')
        when 1 then I18n.t('views.statable.inwork')
        when 2 then I18n.t('views.statable.canceled')
        when 3 then I18n.t('views.statable.applied')
        when 4 then I18n.t('views.statable.reversed')

  class self.FolderViewModel
    constructor: (data) ->
      @documents = ko.observableArray(data.objects)
      @page = ko.observable(data.page || 1)
      @per_page = ko.observable(data.per_page)
      @count = ko.observable(data.count)
      @range = ko.observable(@rangeGenerate())
      @orders = {}

      @params =
        like: @filter
        page: @page
        per_page: @per_page

    onDataReceived: (data) =>
      #do something

    clearData: =>
      @documents([])
      @count([])
      @range(@rangeGenerate())

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
        @onDataReceived(data)
      )

    rangeGenerate: =>
      startRange = if @count() then (@page() - 1)*@per_page() + 1 else 0
      endRange = (@page() - 1)*@per_page() + @per_page()
      endRange = @count() if endRange > @count()
      "#{startRange}-#{endRange}"

    filterData: =>
      @page(1)
      @getPaginateData()

    clearFilter: =>
      for attr, value of @filter
        value('')

    sortBy: (object, event) =>
      el = $(event.target).find('span')
      target = $(event.target)
      unless el.length
        el = $(event.target)
        target = $(event.target).parent()


      key = "#{target.attr("id")}"
      if @orders[key]?
        @orders[key] = !@orders[key]
        el.toggleClass('ui-icon ui-icon-triangle-1-s')
        el.toggleClass('ui-icon ui-icon-triangle-1-n')
      else
        @orders = {}
        @orders[key] = true
        target.siblings().find('span').removeClass(
          'ui-icon ui-icon-triangle-1-n ui-icon-triangle-1-s')
        el.addClass('ui-icon ui-icon-triangle-1-s')

      if @orders[key] == true
        @params['order'] = {}
        @params['order']['type'] = 'asc'
      else
        @params['order'] = {}
        @params['order']['type'] = 'desc'
      @params['order']['field'] = key
      @getPaginateData()

  class self.TreeViewModel extends FolderViewModel
    constructor: (data) ->
      super(data)
      for object in @documents()
        object.subitems = ko.observable(null)

    getPaginateData: =>
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        for object in data.objects
          object.subitems = ko.observable(null)
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

    filterData: =>
      @page(1)
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        for object in data.objects
          object.subitems = ko.observable(null)
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

    expandTree: (object, event) =>
      el = $(event.target).find('span')
      el = $(event.target) unless el.length
      el.toggleClass('ui-icon-circle-plus')
      el.toggleClass('ui-icon-circle-minus')

      if object.subitems() == null
        params = @generateChildrenParams(object)
        $.getJSON(@generateItemsUrl(object), params, (data) =>
          object.subitems(@createChildrenViewModel(data, params, object))
        )
      else
        object.subitems(null)

  class self.GroupedViewModel extends TreeViewModel
    constructor: (data, report, filter) ->
      @route = report
      @url = "/#{@route}/group.json"
      @group_by = ko.observable(filter.group_by)

      super(data)

      @params =
        page: @page
        per_page: @per_page
        group_by: @group_by()

      @group_by.subscribe(@groupBy)

    generateItemsUrl: (object) => "/#{@route}/data.json"

    groupBy: =>
      if @group_by() == ''
        location.hash = "##{@route}"
      else
        location.hash = "##{@route}?group_by=#{@group_by()}"

  class HomeViewModel
    constructor: ->
      $.sammy( ->
        this.get('#helps', ->
          $.get('/helps', {}, (form) ->
            $('.paginate').hide()
            $('#container_documents').html(form)
          )
        )
        this.get('#helps/:id', ->
          id = this.params.id
          $.get("/helps/#{id}", {}, (form) ->
            $('.paginate').hide()
            $('#container_documents').html(form)
            scrolling()
          )
        )
        this.get('#inbox', ->
          $.get('/inbox', {}, (form) ->
            $.getJSON('/inbox.json', {}, (objects) ->
              toggleSelect('inbox')
              $('.paginate').show()
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(new DocumentsViewModel(objects, 'inbox'), $('#main').get(0))
            )
          )
        )
        this.get('#archive', ->
          $.get('/archive', {}, (form) ->
            $.getJSON('/archive.json', {}, (objects) ->
              toggleSelect('archive')
              $('.paginate').show()
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(new DocumentsViewModel(objects, 'archive'), $('#main').get(0))
            )
          )
        )
        this.get('#settings/new', ->
          $.get('/settings/preview', {}, (form) ->
            $.getJSON('/settings/new.json', {}, (data) ->
              toggleSelect()
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(new SettingsViewModel(data), $('#container_documents').get(0))
            )
          )
        )
        this.get('#settings', ->
          $.get('/settings/preview', {}, (form) ->
            $.getJSON('/settings.json', {}, (data) ->
              toggleSelect()
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(new SettingsViewModel(data, true), $('#container_documents').get(0))
            )
          )
        )
        this.get('#documents/:type/new', ->
          type = this.params.type
          $.get("/#{type}/preview", {}, (form) ->
            $.getJSON("/#{type}/new.json", {}, (object) ->
              toggleSelect("#{type}_new")

              viewModel = switch type
                when 'allocations'
                  new AllocationViewModel(object)
                when 'waybills'
                  new WaybillViewModel(object)
                when 'users'
                  new UserViewModel(object)
                when 'groups'
                  new GroupViewModel(object)
                when 'assets'
                  new AssetViewModel(object)
                when 'money'
                  new MoneyViewModel(object)
                when 'places'
                  new PlaceViewModel(object)
                when 'entities'
                  new EntityViewModel(object)
                when 'quote'
                  new QuoteViewModel(object)
                when 'legal_entities'
                  new LegalEntityViewModel(object)
                when 'deals'
                  new DealViewModel(object)

              ko.cleanNode($('#main').get(0))
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
                when 'allocations'
                  new AllocationViewModel(object, true)
                when 'waybills'
                  new WaybillViewModel(object, true)
                when 'users'
                  new UserViewModel(object, true)
                when 'groups'
                  new GroupViewModel(object, true)
                when 'assets'
                  new AssetViewModel(object, true)
                when 'money'
                  new MoneyViewModel(object, true)
                when 'places'
                  new PlaceViewModel(object, true)
                when 'entities'
                  new EntityViewModel(object, true)
                when 'quote'
                  new QuoteViewModel(object, true)
                when 'legal_entities'
                  new LegalEntityViewModel(object, true)
                when 'deals'
                  new DealViewModel(object, true)
                when 'quote'
                  new QuoteViewModel(object, true)

              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
        this.get('#warehouses/report', ->
          filter = this.params.toHash()
          $.get("/warehouses/report", {}, (form) ->
            $.getJSON("/warehouses/report.json", normalizeHash(filter), (data) ->
              toggleSelect("warehouses_report")
              $('.paginate').show()
              viewModel = new WarehouseResourceReportViewModel(data, filter)
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#main').get(0))
            )
          )
        )
        this.get('#warehouses/foremen', ->
          $.get("/warehouses/foremen", {}, (form) ->
            $.getJSON("/warehouses/foremen.json", {}, (data) ->
              toggleSelect("warehouses_foremen")
              $('.paginate').show()
              viewModel = new WarehouseForemanReportViewModel(data)
              ko.cleanNode($('#main').get(0))
              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#main').get(0))
            )
          )
        )
        this.get('#:report', ->
          report = this.params.report
          delete this.params.report
          filter = this.params.toHash()
          if filter.group_by?
            $.get("/#{report}/group",  {}, (form) ->
              $.getJSON("/#{report}/group.json", normalizeHash(filter), (data) ->
                toggleSelect(report)
                $('.paginate').show()
                viewModel = switch report
                              when 'warehouses'
                                new GroupedWarehouseViewModel(data, filter)
                              when 'balance_sheet'
                                new GroupedBalanceSheetViewModel(data, filter)
                ko.cleanNode($('#main').get(0))
                $('#container_documents').html(form)
                ko.applyBindings(viewModel, $('#main').get(0))
              )
            )
          else if filter.view?
            switch filter.view
              when 'table'
                $.get("/#{report}/list", {}, (form) ->
                  $.getJSON("/#{report}/list.json", normalizeHash(filter), (data) ->
                    toggleSelect(report)
                    viewModel = switch report
                                  when 'waybills'
                                    new WaybillsListViewModel(data, filter)
                                  when 'allocations'
                                    new AllocationsListViewModel(data, filter)
                    ko.cleanNode($('#main').get(0))
                    $('#container_documents').html(form)
                    ko.applyBindings(viewModel, $('#main').get(0))
                  )
                )
          else
            $.get("/#{report}", {}, (form) ->
              $.getJSON("/#{report}/data.json", normalizeHash(filter), (data) ->
                toggleSelect(report)
                $('.paginate').show()
                viewModel = switch report
                  when 'warehouses'
                    new WarehouseViewModel(data)
                  when 'general_ledger'
                    new GeneralLedgerViewModel(data, filter)
                  when 'balance_sheet'
                    new BalanceSheetViewModel(data, filter)
                  when 'transcripts'
                    new TranscriptViewModel(data, filter)
                  when 'users'
                    new UsersViewModel(data)
                  when 'groups'
                    new GroupsViewModel(data)
                  when 'resources'
                    new ResourcesViewModel(data)
                  when 'entities'
                    new EntitiesViewModel(data)
                  when 'places'
                    new PlacesViewModel(data)
                  when 'deals'
                    new DealsViewModel(data)
                  when 'waybills'
                    new WaybillsViewModel(data)
                  when 'allocations'
                    new AllocationsViewModel(data)
                  when 'quote'
                    new QuotesViewModel(data)

                ko.cleanNode($('#main').get(0))
                $('#container_documents').html(form)
                ko.applyBindings(viewModel, $('#main').get(0))
              )
            )
        )
      ).run()

      location.hash = defaultPage if $('#main').length && location.hash.length == 0

    expandResources: (object, event) =>
      @expand($('#slide_menu_resources'), $('#arrow_resources_actions'))

    expandEntities: (object, event) =>
      @expand($('#slide_menu_entities'), $('#arrow_entities_actions'))

    expand: (menu, actions) =>
      if menu.is(":visible")
        actions.removeClass('arrow-down-expand')
        actions.addClass('arrow-right-expand')
      else
        actions.removeClass('arrow-right-expand')
        actions.addClass('arrow-down-expand')
      menu.slideToggle()

    expandDeals: (object, event) =>
      toggle = true
      if $('#slide_menu_deals').is(":visible")
        if event.target.id == 'arrow_actions'
          $('#arrow_actions').removeClass('arrow-down-expand')
          $('#arrow_actions').addClass('arrow-right-expand')
        else
          toggle = false
          location.hash = $('#deals').attr('href')
      else
        if event.target.id == 'deals'
          location.hash = $('#deals').attr('href')
        $('#arrow_actions').removeClass('arrow-right-expand')
        $('#arrow_actions').addClass('arrow-down-expand')
      $("#slide_menu_deals").slideToggle() if toggle

    slide: (object, event) ->
      switch event.target.id
        when 'btn_slide_conditions'
          @slideMenu('#slide_menu_conditions', '#arrow_conditions')
        when 'btn_slide_lists'
          @slideMenu('#slide_menu_lists', '#arrow_lists')
        when 'btn_slide_services'
          @slideMenu('#slide_menu_services', '#arrow_services')

    slideMenu: (slide_id, arrow_id) ->
        if $(slide_id).is(":visible")
          $(arrow_id).removeClass('arrow-up-slide')
          $(arrow_id).addClass('arrow-down-slide')
        else
          $(arrow_id).removeClass('arrow-down-slide')
          $(arrow_id).addClass('arrow-up-slide')
        $(slide_id).slideToggle()

  ko.applyBindings(new HomeViewModel(), $('#body').get(0))
