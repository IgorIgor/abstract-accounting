$ ->
  class self.GroupedViewModel extends FolderViewModel
    constructor: (data, report, filter) ->
      @route = report
      @url = "/#{@route}/group.json"
      @group_by = ko.observable(filter.group_by)

      super(data)

      @params =
        page: @page
        per_page: @per_page
        group_by: @group_by()

      for object in @documents()
        object.subitems = ko.observable(null)

      @group_by.subscribe(@groupBy)

    getPaginateData: =>
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        for object in data.objects
          object.subitems = ko.observable(null)
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )

    groupBy: =>
      if @group_by() == ''
        location.hash = "##{@route}"
      else
        location.hash = "##{@route}?group_by=#{@group_by()}"

    expandTree: (object, event) =>
      el = $(event.target).find('span')
      el = $(event.target) unless el.length
      el.toggleClass('ui-icon-circle-plus')
      el.toggleClass('ui-icon-circle-minus')

      if object.subitems() == null
        params = {}
        switch @group_by()
          when 'place'
            params = {where: {place_id: {equal_attr: object.group_id}}}
          when 'tag'
            params = {where: {asset_id: {equal_attr: object.group_id}}}
        $.getJSON("/#{@route}/data.json", params, (data) =>
          object.subitems(new WarehouseViewModel(data, params))
        )
      else
        object.subitems(null)
