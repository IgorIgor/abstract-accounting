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
      when 'slide_menu_estimate'
        slideShow('#slide_menu_estimate', '#arrow_estimate')
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

  class self.BaseViewModel
    constructor: (paginater = false) ->
      @paginater = ko.observable(paginater)

  class self.ObjectViewModel extends BaseViewModel
    constructor: (object, route, readonly = false)->
      super(false)
      @readonly = ko.observable(readonly)
      @disable = ko.observable(false)
      @object = ko.mapping.fromJS(object)
      @route = route

    ajaxRequest: (type, url, params = {}, refresh = false) =>
      $.ajax(
        type: type
        url: url
        data: params
        complete: (data) =>
          unless data.responseText == ''
            response = JSON.parse(data.responseText)
            if data.status == 500
              @disable(false)
            else
              if response['result'] == 'success'
                hash = ''
                if response['id']
                  hash = if @namespace().length > 0 then "#{@namespace()}/" else ""
                  hash += "#{@route}/#{response['id']}"
                else
                  hash = location.hash
                $.sammy().refresh() if refresh
                location.hash = hash
              else
                @disable(false)
                $('#container_notification').css('display', 'block')
                $('#container_notification ul').css('display', 'block')
                $('#container_notification ul').empty()
                for msg in JSON.parse(data.responseText, (key, value) -> value)
                  $('#container_notification ul')
                    .append($("<li class='server-message'>#{msg}</li>"))
        error: =>
          @disable(false)
      )

    back: -> history.back()

    save: =>
      @disable(true)
      @ajaxRequest('POST', "/#{@route}", normalizeHash(ko.mapping.toJS(@object)))

    disableSave: =>
      @disable() || @readonly()

    disableEdit: =>
      @disable() || !@readonly()

  class self.EditableObjectViewModel extends ObjectViewModel
    constructor: (object, route, readonly = false)->
      super(object, route, readonly)
      @method = 'POST'
      @id_presence = ko.observable(object.id?)

    edit: =>
      @readonly(false)
      @disable(false)
      @method = 'PUT'
      hash = if @namespace().length > 0 then "#{@namespace()}/" else ""
      location.hash = hash + "#{@route}/#{@object.id()}/edit"

    namespace: =>
      "documents"

    save: =>
      @disable(true)
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
    @UNKNOWN: 0
    @INWORK: 1
    @CANCELED: 2
    @APPLIED: 3
    @REVERSED: 4
    constructor: (object, route, readonly = false)->
      super(object, route, readonly)

    visibleApply: =>
      @readonly() && @object.state.can_apply()

    visibleCancel: =>
      @readonly() && @object.state.can_cancel()

    visibleReverse: =>
      @readonly() && @object.state.can_reverse()

    disableButton: =>
      @disable()

    apply: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/apply", {}, true)

    cancel: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/cancel", {}, true)

    reverse: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/reverse", {}, true)

    getState: (state) ->
      switch state
        when 0 then I18n.t('views.statable.unknown')
        when 1 then I18n.t('views.statable.inwork')
        when 2 then I18n.t('views.statable.canceled')
        when 3 then I18n.t('views.statable.applied')
        when 4 then I18n.t('views.statable.reversed')

  class self.FolderViewModel extends BaseViewModel
    constructor: (data) ->
      super(true)
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

    show: (object) =>
      type = @getType(object)
      location.hash = "#{@namespace()}/#{type}/#{object.id}"

    namespace: =>
      "documents"

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
        @onDataReceived(data)
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
      @getPaginateData()

    clearFilter: =>
      for attr, value of @filter
        if typeof this["clearFilter#{attr.camelize()}"] == 'function'
          this["clearFilter#{attr.camelize()}"]()
        else
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

    onDataReceived: (data) =>
      for object in data.objects
        object.subitems = ko.observable(null)
      super(data)

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
